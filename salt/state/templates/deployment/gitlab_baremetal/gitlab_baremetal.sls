{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config %}

{%- set action = args.action if 'action' in args else 'all' %}

{%- if action in ['all','install'] %}

gitlab-baremetal-package-installed:
    pkg.installed:
        - name:      gitlab-ce
        - fromrepo:  gitlab-ce
        - version:   {{pillar.svd.cots.gitlab.version}}
        - allow_updates: True

gitlab-baremetal-copy-original-config:
    cmd.run:
        - name:      cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.orig
        - unless:    test -f /etc/gitlab/gitlab.rb.orig
        - creates:   /etc/gitlab/gitlab.rb.orig
        - require:
            - pkg:   gitlab-baremetal-package-installed

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}


# This file deliberately does not specify user,group,perms. The gitlab package install will configure it.
gitlab-baremetal-config-dir:
    file.directory:
        - name:  /etc/gitlab

gitlab-baremetal-config-file:
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

gitlab-baremetal-configured:
    cmd.run:
        - name:     gitlab-ctl reconfigure
        - onlyif:   test -f /usr/bin/gitlab-ctl
        - onchanges:
            - file: gitlab-baremetal-config-file

{%     if 'mattermost' in config and 'app_id' in config.mattermost and 'token' in config.mattermost %}

gitlab-mattermost-integration-appid:
    file.managed:
        - name: /var/opt/gitlab/mattermost/env/MM_GITLABSETTINGS_ID
        - contents: |
            {{config.mattermost.app_id}} 

gitlab-mattermost-integration-token:
    file.managed:
        - name: /var/opt/gitlab/mattermost/env/MM_GITLABSETTINGS_SECRET
        - contents: |
            {{config.mattermost.token}}

gitlab-mattermost-restarted:
    cmd.run:
        - name: |
            gitlab-ctl stop mattermost
            sleep 10
            gitlab-ctl start mattermost
        - onchanges:
            - file: gitlab-mattermost-integration-token
            - file: gitlab-mattermost-integration-appid
            
{%     endif %}
{% endif %}

{%- if action in [ 'all', 'activate'] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

gitlab-service:
    service.{{'running' if activated else 'dead'}}:
        - name: gitlab-runsvdir 
        - enable: {{activated}} 

{%- endif %}
