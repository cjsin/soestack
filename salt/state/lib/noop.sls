{% macro notice(msg) -%}

NOTICE-{{salt.uuids.short()}}:
    noop.notice:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro log(msg) -%}

LOG-{{salt.uuids.short()}}:
    noop.log:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro warning(msg) -%}

WARNING-{{salt.uuids.short()}}:
    noop.warning:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro error(msg) -%}

ERROR-{{salt.uuids.short()}}:
    noop.error:
        - name: |-
            {{ msg|indent(12) }}

{% endmacro %}

{% macro pprint(name,obj) -%}

PPRINT-{{name}}-{{salt.uuids.short()}}:
    noop.pprint:
        - data: {{ obj | json }}

{% endmacro %}
