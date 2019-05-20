{%- macro short() -%}
{{salt['cmd.exec_code']('python','import uuid; print(str(uuid.uuid4())); ')[:8]}}
{%- endmacro %}
