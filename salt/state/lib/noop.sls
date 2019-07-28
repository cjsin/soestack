{# NOTE that all these produce json so that they can be commented out where they are called #}
{# (due to being on a single line) #}
{% macro notice(msg) -%}
{{sls}}.NOTICE-{{salt.uuids.short()}}:  { 'noop.notice': [ {'name': {{msg|json}} } ] }
{% endmacro %}

{% macro log(msg) -%}
{{sls}}.LOG-{{salt.uuids.short()}}:  { 'noop.log': [ {'name': {{msg|json}} } ] }
{% endmacro %}

{% macro warning(msg) -%}
{{sls}}.WARNING-{{salt.uuids.short()}}: { 'noop.warning': [ {'name': {{msg|json}} } ] }
{% endmacro %}

{% macro error(msg) -%}
{{sls}}.ERROR-{{salt.uuids.short()}}: { 'noop.warning': [ {'name': {{msg|json}} } ] }
{% endmacro %}

{% macro pprint(name,obj) -%}
{{sls}}.PPRINT-{{name}}-{{salt.uuids.short()}}: { 'noop.pprint': [ {'data': {{obj|json}} } ] }
{% endmacro %}
