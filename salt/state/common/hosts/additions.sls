#!stateconf yaml . jinja
{%- if 'network' in pillar and 'hostfile-additions' in pillar.network %}
{%-     for ip, names in pillar.network['hostfile-additions'].iteritems() %}

.update-{{ip}}-ip:
    cmd.run:
        - name: 'sed -i "/^{{ip}}[[:space:]]/ d" /etc/hosts && echo "{{ip}} {{names}}" >> /etc/hosts'
        - unless: egrep -q "^{{ip}}[[:space:]]+{{names}}" /etc/hosts

{%-     endfor %}
{%- endif %}

