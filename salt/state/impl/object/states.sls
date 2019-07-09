{%- set this = _args.this %}
{%- if 'states' in this %}
{#-     each item should be a registered method which will produce states #}
{%-     for method_name in states %}
{%-         set _args = { 'this': this, 'method_name': method_name } %}
{%-         include('impl' ~ '/object/call.sls') with context ignore missing %}
{%-     endfor %}
{%- endif %}
