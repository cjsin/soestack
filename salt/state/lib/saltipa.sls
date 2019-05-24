{% macro check_ticket() -%}

check-ipa-working:
    noop.notice:
        - name: |-
            {{ salt.saltipa.check_ticket()[0] }}

{% endmacro %}
