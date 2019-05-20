#!stateconf yaml . jinja

{%- if 'dhcp' in pillar and 'dnsmasq' in pillar.dhcp and pillar.dhcp.dnsmasq.enabled %}
{%-     set dhcp = pillar.dhcp.dnsmasq %}

include:
    - .dnsmasq
    - server.dnsmasq.dhcp-only

.dnsmasq-config:
    file.managed:
        - name: /etc/dnsmasq.d/dhcp.conf
        - contents: |
            dhcp-range={{dhcp.range[0]}},{{dhcp.range[1]}},{{dhcp.lease_time}}m

.disable-dhcpd:
    service.dead:
        - name: dhcpd

.reload-dnsmasq:
    service.running:
        - name: dnsmasq
        - enable: True
        - onchanges:
            - file: server.dnsmasq.dhcp::dnsmasq-config


{%- endif %}
