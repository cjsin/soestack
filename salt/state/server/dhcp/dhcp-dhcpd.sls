#!stateconf yaml . jinja

{%- if 'dhcp' in pillar and 'dhcpd' in pillar.dhcp and pillar.dhcp.dhcpd.enabled %}
{%-     set dhcp = pillar.dhcp.dhcpd %}
{%-     set dns = pillar.dns.network if 'network' in pillar and 'dns' in pillar.dns else {} %}

.dhcp-config:
    file.managed:
        - name: /etc/dhcp/dhcpd.conf
        - user: root
        - group: root
        - mode: '0644'
        - source: salt://{{slspath}}/dhcpd.conf.jinja
        - template: jinja
        - context:
            dns:  {{dns|json}}
            dhcp: {{dhcp|json}}


{%-     with args = { 'nugget_name': 'dhcp-server', 'required_by': slspath } %}
{%          include('templates/nugget/install.sls') with context %}
{%-     endwith %}

{%- endif %}
