{%- set errors=[] %}
{%- if this is defined and classreg is defined %}
{%-     set superclasses=[] %}
{%-     for k,v in this.iteritems() %}
{%          if k[0:1] == '+' %}
{%-             set classname = k[1:] %}
{%-             if classname in classreg %}
{%-                 do superclasses.append(classname) %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}
{%-     if superclasses|length < 1 %}
{%-         do errors.append(this.name ~ 'has no class defined' %}
{%-     endif %}
{%- endif %}
{%- if errors %}
{{sls}}-errors:
    noop.error:
        - text: |
            {%- for e in errors %}
            {{e}}
            {%- endfor %}
{%- endif %}
