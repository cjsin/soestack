{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}

{%- set action = args.action if 'action' in args else 'all' %}

{%- if action in ['all','install'] %}

{{sls}}.gitlab-baremetal-package-installed:
    pkg.installed:
        - name:      gitlab-ce
        - fromrepo:  gitlab-ce
        - version:   {{pillar.versions.cots.gitlab.version}}
        - allow_updates: True

{{sls}}.gitlab-baremetal-copy-original-config:
    cmd.run:
        - name:      cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.orig
        - unless:    test -f /etc/gitlab/gitlab.rb.orig
        - creates:   /etc/gitlab/gitlab.rb.orig
        - require:
            - pkg:   {{sls}}.gitlab-baremetal-package-installed

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{{sls}}.gitlab-{{deployment_name}}-{{deployment_type}}-token-script:
    file.managed:
        - name: /usr/local/bin/gitlab-retrieve-runner-token
        - user: root
        - group: root
        - mode:  '0700'
        - source: salt://templates/deployment/gitlab_baremetal/gitlab-retrieve-runner-token.sh.jinja
        - template: jinja
        - context: 
            config: {{config}}

{{sls}}.gitlab-{{deployment_name}}-{{deployment_type}}-mattermost-token-script:
    file.managed:
        - name: /usr/local/bin/gitlab-retrieve-app-token
        - user: root
        - group: root
        - mode:  '0700'
        - source: salt://templates/deployment/gitlab_baremetal/gitlab-retrieve-app-token.sh.jinja
        - template: jinja
        - context: 
            config: {{config}}

# This file deliberately does not specify user,group,perms. The gitlab package install will configure it.
{{sls}}.gitlab-baremetal-config-dir:
    file.directory:
        - name:  /etc/gitlab

{{sls}}.gitlab-baremetal-config-file:
    file.managed:
        - name:         /etc/gitlab/gitlab.rb
        - user:         root
        - group:        root
        - mode:         '0644'
        - source:       salt://templates/deployment/gitlab_baremetal/gitlab.rb.jinja
        - template:     jinja
        - context: 
            deployment_name: {{deployment_name}}
            deployment:      {{deployment|json()}}
            config:          {{config|json()}}

{{sls}}.gitlab-baremetal-initial-configure-script:
    file.managed:
        - name: /root/gitlab-initial-configure 
        - user: root
        - group: root
        - mode: '0755'
        - template: jinja 
        - contents: |
            #!/bin/bash
            recordfile=/var/log/gitlab-configured.success
            [[ -f "${recordfile}" ]] && exit 0

            for xxx in pw-gitlab-admin gitlab-runner-registration-token
            do
                salt-secret "${xxx}" > /dev/null 2> /dev/null || generate-passwords "${xxx}" --min-length=20
            done
            
            export GITLAB_ROOT_PASSWORD=$(salt-secret "pw-gitlab-admin")
            export GITLAB_ROOT_EMAIL="root@localhost.localdomain"
            export GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN=$(salt-secret "gitlab-runner-registration-token")
            export GITLAB_PROMETHEUS_METRICS_ENABLED="false"
            
            # Systemctl hangs while starting gitlab-runsvdir. 
            # Performing a daemon-reexec here is an attempt to fix that systemd bug
            systemctl daemon-reexec
            sleep 5

            start_time=$(date +%s)
            too_long=$((start_time+300)) #5 minutes means it's likely hung
            (
                if gitlab-ctl reconfigure >> /var/log/gitlab-reconfigure.log 2>&1
                then 
                    touch /var/log/gitlab-configured.success
                fi
                gitlab-retrieve-runner-token gitlab-runner-registration-token
            ) &
            bg_pid=$!
            echo "Waiting for gitlab reconfigure (because systemd hangs)"
            while sleep 5
            do 
                now=$(date +%s)
                if [[ -f /var/log/gitlab-configured.success ]]
                then 
                    break
                elif [[ "${now}" -gt "${too_long}" ]]
                then
                    if ps -wef | egrep 'systemctl.*start.*runsvdir'
                    then
                        systemctl daemon-reexec
                        kill $bg_pid; 
                    fi
                fi
            done 

{{sls}}.gitlab-baremetal-reconfigured:
    cmd.run:
        - name:     gitlab-ctl reconfigure
        - onlyif:   test -f /var/log/gitlab-configured.success
        - onchanges:
            - file: {{sls}}.gitlab-baremetal-config-file

{{sls}}.gitlab-baremetal-initial-configure:
    cmd.run:
        - name:     /root/gitlab-initial-configure 
        - onlyif:   test -f /usr/bin/gitlab-ctl
        - unless:   test -f /var/log/gitlab-configured.success
        - onchanges:
            - file: {{sls}}.gitlab-baremetal-config-file

{{sls}}.test-data-import-script:
    file.managed:
        - name: /usr/local/bin/gitlab-import-test-repos
        - source: salt://templates/deployment/gitlab_baremetal/gitlab-import-test-repos.sh.jinja
        - user: root
        - group: root 
        - mode: '0750'

{{sls}}.test-data-import:
    cmd.run:
        - name:     /usr/local/bin/gitlab-import-test-repos
        - unless:   test -d /d/local/data/gitlab-import/test/

{%- endif %}

{%- if action in [ 'all', 'activate'] %}

{#-     Note that gitlab uses gitlab-runsvdir service, which starts/stops its component parts #}
{#-     There, to stop it, we need to use gitlab-ctl, then stop gitlab-runsvdir #}
{#-     Whereas to start it, we need to first start gitlab-runsvdir, and then use gitlab-ctl if necessary #}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{%-     if not activated %}

{{sls}}.gitlab-services-stopped:
    cmd.run:
        - name: gitlab-ctl stop
        - onlyif: gitlab-ctl status | egrep 'up:'

{{sls}}.gitlab-runsvdir-stopped:
    #service.dead:
    #    - name: gitlab-runsvdir 
    #    - enable: {{activated}} 
    cmd.run:
        - name: systemctl disable gitlab-runsvdir ; systemctl stop --no-ask-password gitlab-runsvdir


{%-     else %}

# There is a systemd bug (as usual) (going back 8 years) whereby it sits there 
# like a piece of shit unless run with the --no-ask-password option 
# (even when the service could not be simpler and does not need any kind of password entry)
{{sls}}.gitlab-runsvdir:
    cmd.run:
        - name: systemctl enable gitlab-runsvdir ; systemctl start --no-ask-password gitlab-runsvdir
    #service.running:
    #    - name: gitlab-runsvdir 
    #    - enable: {{activated}} 

{{sls}}.gitlab-services:
    cmd.run:
        - name: gitlab-ctl start
        {#- If not already running, gitlab-runsvdir will start the services when it starts #}
        {#- so we give it a chance to do that first before checking #}
        - onlyif: sleep 5; gitlab-ctl status | egrep 'down:'

{%-     endif %}
{%- endif %}

