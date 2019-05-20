#!stateconf yaml . jinja

{#- The sshd config file is only updated if the data is not empty #}
{%- if 'ssh' in pillar and 'sshd' in pillar.ssh and 'sshd_config' in pillar.ssh.sshd and pillar.ssh.sshd_config %}

.cfgfile:
    file.managed:
        - name:   /etc/ssh/sshd_config
        - user:   root
        - group:  root
        - mode:   '0600'
        - contents_pillar: ssh:sshd:sshd_config

{%- endif %}


.service-enabled:
    service.running:
        - name:   sshd
        - enable: {{pillar.ssh.sshd.enabled}}
        - onchanges:
            - file: sshd.sshd_config::cfgfile

