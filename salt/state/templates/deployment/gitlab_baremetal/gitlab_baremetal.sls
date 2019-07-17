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

{{sls}}.gitlab-{{deployment_name}}-{{deployment_type}}-mattermost-token-script:
    file.managed:
        - name: /usr/local/bin/gitlab-retrieve-app-token
        - user: root
        - group: root
        - mode:  '0700'
        - source: salt://templates/deployment/gitlab_baremetal/gitlab-retrieve-app-token.sh.jinja
        - template: jinja

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
        - source:       salt://{{slspath}}/gitlab.rb.jinja
        - template:     jinja
        - context: 
            deployment_name: {{deployment_name}}
            deployment:      {{deployment|json()}}
            config:          {{config|json()}}

{{sls}}.gitlab-baremetal-configured:
    cmd.run:
        - name: gitlab-ctl reconfigure >> /var/log/gitlab-reconfigure.log 2>&1 ; gitlab-retrieve-runner-token
        - onlyif:   test -f /usr/bin/gitlab-ctl
        - onchanges:
            - file: {{sls}}.gitlab-baremetal-config-file

{#-    #This code is ready to be removed because the auto integration is now working - once the slash at the end of the mattermost URL was removed. #}
{%-    set obsolete = True %}
{%-    if not obsolete %}
{%-        if 'mattermost' in config and 'app_id' in config.mattermost and 'token' in config.mattermost %}
{%-            set mattermost = config.mattermost %}
{%-            if mattermost.app_id and mattermost.token and mattermost.app_id != 'unset' and mattermost.token != 'unset' %}

{{sls}}.gitlab-mattermost-integration-appid:
    file.managed:
        - name: /var/opt/gitlab/mattermost/env/MM_GITLABSETTINGS_ID
        - contents: |
            {{config.mattermost.app_id}} 

{{sls}}.gitlab-mattermost-integration-token:
    file.managed:
        - name: /var/opt/gitlab/mattermost/env/MM_GITLABSETTINGS_SECRET
        - contents: |
            {{config.mattermost.token}}

{{sls}}.gitlab-mattermost-restarted:
    cmd.run:
        - name: |
            gitlab-ctl stop mattermost
            sleep 10
            gitlab-ctl start mattermost
        - onchanges:
            - file: {{sls}}.gitlab-mattermost-integration-token
            - file: {{sls}}.gitlab-mattermost-integration-appid
{%-            endif %}
{%-        endif %}
{%-     endif %}

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
    service.dead:
        - name: gitlab-runsvdir 
        - enable: {{activated}} 

{%-     else %}

{{sls}}.gitlab-runsvdir:
    service.running:
        - name: gitlab-runsvdir 
        - enable: {{activated}} 

{{sls}}.gitlab-services:
    cmd.run:
        - name: gitlab-ctl start
        {#- If not already running, gitlab-runsvdir will start the services when it starts #}
        {#- so we give it a chance to do that first before checking #}
        - onlyif: sleep 5; gitlab-ctl status | egrep 'down:'

{%-     endif %}
{%- endif %}

