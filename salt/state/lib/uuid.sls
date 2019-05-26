{%- macro short() -%}
{{salt['uuid.short']()}}
{%- endmacro %}
