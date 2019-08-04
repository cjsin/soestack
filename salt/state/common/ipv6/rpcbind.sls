#!stateconf yaml . jinja

{%- if 'network' in pillar and 'ipv6' in pillar.network %}
{%-     set mode = pillar.network.ipv6.mode if 'mode' in pillar.network.ipv6 else 'default' %}

{{sls}}.packages:
    pkg.installed:
        - pkgs:
            - rpcbind
            - libtirpc

{{sls}}.ipv6-{{mode}}:
    file.{{'comment' if mode in [ 'lo-only', 'disable' ] else 'uncomment' }}:
        - name:  /usr/lib/systemd/system/rpcbind.socket
        - regex: '^Listen(Stream|Datagram)=\[::'
        - char: '#'

{# for some reason a systemctl daemon-reload does not seem to be required for this change to take effect #}
{{sls}}.socket-restarted:
    service.running:
        - name: rpcbind.socket
        - onchanges:
            - file: {{sls}}.ipv6-{{mode}}

{%- endif %}
