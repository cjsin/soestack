{%- if 'tftp' in pillar and 'implementation' in pillar.tftp and pillar.tftp.implementation == 'xinetd' %}

include:
    - ..dnsmasq.dhcp

{%- endif %}
