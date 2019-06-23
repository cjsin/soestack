#!stateconf yaml . jinja

{%- if 'network' in pillar and 'ipv6' in pillar.network %}
{%-     set mode = pillar.network.ipv6.mode if 'mode' in pillar.network.ipv6 else 'default' %}

{%-     if mode in [ 'lo-only', 'enable', 'disable', 'default' ] %}

.sysctls:
    file.managed:
        - name:     /etc/sysctl.d/40-ipv6.conf
        - user:     root 
        - group:    root
        - mode:     '0644'
        - contents_pillar: lookup:ipv6:sysctls:{{mode}}

.reload:
    cmd.wait:
        - name: sysctl --system
        - onchanges:
            - file: {{sls}}::sysctls

{%-     endif %}
{%- endif %}
