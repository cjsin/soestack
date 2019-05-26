#!stateconf yaml . jinja

{%- if 'email' in pillar and pillar.email and 'aliases' in pillar.email  and pillar.email.aliases %}

{%-     set reqs = [] %}
{%-     for user_name, deliver_to in pillar.email.aliases.iteritems() %}
{%-         set state_name='-'.join(['update-aliases', user_name, deliver_to]) %}
{%-         do reqs.append(state_name) %}

.{{state_name}}:
    cmd.run:
        - name: "sed -i -e '/^{{user_name}}[[:space:]]*:/ d' -e '$ a{{user_name}}: {{deliver_to}}' /etc/aliases"
        - unless: egrep '^{{user_name}}[[:space:]]*:[[:space:]]*{{deliver_to}}[[:space:]]*$' /etc/aliases 

{%-    endfor %}

.run-newaliases:
    cmd.run:
        - name: newaliases
        - onchanges:
            {%- for r in reqs %}
            - cmd: {{r}}
            {%- endfor %}

{%- endif %}
