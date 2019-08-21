{%  set tests = pillar.tests if 'tests' in pillar else {} %}
{%- set defaults = tests.defaults if 'defaults' in tests else {} %}

{%- for n, t in tests.iteritems() %}
{%-     if n != 'defaults' %}
{%-         for ttype, tdata in t.iteritems() %}
{%-             set type_defaults = defaults[ttype] if ttype in defaults else {} %}
{%-             set props = salt['ordered.odict']() %}
{%-             do props.update(type_defaults) %}
{%-             do props.update(tdata) %}
{{sls}}.{{n}}.{{ttype}}:
    cmd.script:
        - source:   salt://{{slspath}}/types/{{ttype}}-test.sh.jinja
        - template: jinja
        - context:
            ttype: '{{ttype}}'
            n: {{n}}
            t: {{props|json}}
{%-         endfor %}
{%-     endif %}
{%- endfor %}
