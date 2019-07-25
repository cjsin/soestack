{%- set ruleset_name = args.ruleset_name %}
{%- set action_name = args.action_name %}
{%- set data = args.data %}
{%- set prefix = args.prefix %}
{%- set suffix = args.suffix %}
{%- set valid_keys = [] %}

{{sls}}.{{prefix}}.firewall.complex.{{ruleset_name}}.{{action_name}}{{suffix}}:
    iptables.insert:
        - position:  1
        {%- for key, value in data.iteritems() %}
        {%-     if (not valid_keys) or key in valid_keys %}
        - {{key}}:       {{data[key]}}
        {%-     endfor %}
        {%- endif %}
        - save:      True
