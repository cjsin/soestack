{%- if 'network' in pillar and 'hostfile-additions' in pillar.network %}
{%-     for ip, names in pillar.network['hostfile-additions'].iteritems() %}

.update-{{ip}}:
    cmd.run:
        - name: 'sed -i "/{{ip}}/ d" /etc/hosts && echo "{{ip}} {{names}}" >> /etc/hosts'
        - unless: egrep -s "{{ip}}[[:space:]]+{{names}}" /etc/hosts

{%-     endfor %}
{%- endif %}

