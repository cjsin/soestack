{%- set this = _args.this %}
{%- set prefix, suffix  = salt.uuid.ids() %}
{%- if this is not defined %}
null-object-error-{{suffix}}:
    noop.error:
        - text: Object state template was called without a 'this' object defined.
{%- elif '_search' not in this %}
incomplete-object-definition-error-{{suffix}}:
    noop.error:
        - text: |
            Object is missing class hierarchy details.
            {{this|json|indent(12)}}
{%- else %}
{%-   set _args={'this': this, 'method_name': 'states'} %}
{%-   include('impl' ~ '/object/call.sls') with context ignore missing %}
{%- endif %}
