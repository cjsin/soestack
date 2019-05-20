#!stateconf yaml . jinja

{%- if 'tftp' in pillar and 'implementation' in pillar.tftp and pillar.tftp.implementation == 'xinetd' %}

{%-     with args = { 'nugget_name': 'tftp-server', 'required_by': slspath } %}
{%          include('templates/nugget/install.sls') with context %}
{%-     endwith %}

.enable-tftp:
    file.replace:
        - name: /etc/xinetd.d/tftp
        - pattern: 'disable[[:space:]]+=[[:space:]]*yes'
        - repl:    'disable = no'

.service-restarted:
    service.running:
        - name: xinetd
        - enable: True
        - onchanges:
            - file: server.tftp::enable-tftp

{%- endif %}
