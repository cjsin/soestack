{#- 
This template requires the following defined within _args:
    this         - an object definition, which must have a 'hierarchy' and 'implementation'
    method_name  - the method to call for this object
#}
{%- set this = _args.this %}
{%- set method_name = _args.method_name %}
{%- set implementation = 'impl' %}
{#- the hierarchy will be searched for classes that implement the specified method #}
{%- if method_name[0] == '+' %}
{%-     set parts = method_name[1:].split('.') %}
{%-     if parts|length > 0) %}
{%-         set _class  = parts[0] %}
{%-         set _method = parts[1] %}
{%-         set _file   = [implementation, _class, _method ]|join('/') ~ '.sls' %}
{%-         include(_file) with context ignore missing %}
{%-     endif %}
{%- else %}
{%-     set _method = method_name %}
{#-     # NOTE this processes the parents in the hierarchy only #}
{%-     for _class in this._hierarchy %}
{%-         if 'methods' in _class and method_name in _class.methods %}
{%-             set _file = [implementation, _class, _method ]|join('/') ~ '.sls' %}
{%              include(_file) with context ignore missing %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
