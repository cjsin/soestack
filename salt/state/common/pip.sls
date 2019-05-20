#!stateconf yaml . jinja

{%- if 'pip' in pillar and 'host_config' in pillar.pip %}

.etc-pip-conf:
    file.managed:
        - name:     /etc/pip.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents_pillar: pip:host_config 

{%- endif %}

