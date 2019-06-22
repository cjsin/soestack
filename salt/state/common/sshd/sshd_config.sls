#!stateconf yaml . jinja

{#- The sshd config file is only updated if the data is not empty #}
{%- if 'ssh' in pillar and 'sshd' in pillar.ssh %}
{%-     set sshd = pillar.ssh.sshd %}
{%-     if sshd and 'sshd_config' in sshd and sshd.sshd_config %}
{%-         if sshd.sshd_config and sshd.sshd_config not in ['', 'unset' ] %}

.cfgfile:
    file.managed:
        - name:   /etc/ssh/sshd_config
        - user:   root
        - group:  root
        - mode:   '0600'
        - contents_pillar: ssh:sshd:sshd_config

{%-         endif %}
{%-     endif %}

.service-enabled:
    service.running:
        - name:   sshd
        - enable: {{'enabled' in sshd and sshd.enabled}}
        - onchanges:
            - file: {{sls}}::cfgfile

{%- endif %}
