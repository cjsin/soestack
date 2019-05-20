
{%- if 'dhcp' in pillar and 'dnsmasq' in pillar.dhcp and pillar.dhcp.dnsmasq.enabled %}
{%-     set dhcp = pillar.dhcp.dnsmasq %}

include:
    - ..dnsmasq.dhcp

{%- endif %}
