{%- set prefix, suffix  = salt.uuid.ids(args) %}
{{prefix}}firewall-rule-{{args.name}}{{suffix}}:
    iptables.insert:
        - position:  1
        {#- # TODO - add all valid keys #}
        {%- for key in [ 'table', 'chain', 'jump', 'match', 'connstate', 'dport', 'protocol', 'sport', 'save' ] %}
        {%-     if key in data %}
        - {{key}}:       {{data[key]}}
        {%-     endfor %}
        {%- endif %}
        - save:      True
