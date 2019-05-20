#!stateconf yaml . jinja

{%- if 'dhcp' in pillar and 'dnsmasq' in pillar.dhcp and pillar.dhcp.dnsmasq.enabled %}
{%-     set dhcp = pillar.dhcp.dnsmasq %}

{%- if 'dhcp_only' in dhcp and dhcp.dhcp_only %}

.dnsmasq-config:
    file.managed:
        - name: /etc/dnsmasq.d/dhcp-only.conf
        - contents: |
            port=0

{%- else %}

.remove-dhcp-only:
    file.absent:
        - name: /etc/dnsmasq.d/dhcp-only.conf

{%- endif %}

include:
  - .dhcp

{%- endif %}
