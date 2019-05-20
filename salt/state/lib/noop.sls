{% macro notice(msg) -%}

NOTICE-{{salt.uuid.short()}}:
    noop.notice:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro log(msg) -%}

LOG-{{salt.uuid.short()}}:
    noop.log:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro warning(msg) -%}

WARNING-{{salt.uuid.short()}}:
    noop.warning:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro error(msg) -%}

ERROR-{{salt.uuid.short()}}:
    noop.error:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro pprint(name,obj) -%}

PPRINT-{{name}}-{{salt.uuid.short()}}:
    noop.pprint:
        - data: {{ obj | json }}

{% endmacro %}
