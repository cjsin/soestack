{%- import 'lib/noop.sls' as noop %}
{%- set test_type = args.test_type if 'test_type' in args else '' %}
{%- if test_type %}

{%      set tests = pillar.tests if 'tests' in pillar else salt['ordered.odict']() %}
{%-     set defaults = tests.defaults if 'defaults' in tests else salt['ordered.odict']() %}
{%-     set type_defaults = defaults[test_type] if test_type in defaults else salt['ordered.odict']() %}
{%      set found = salt['ordered.odict']() %}
{%-     for n, t in tests.iteritems() %}
{%-         for ttype, tdata in t.iteritems() %}
{%-             if ttype == test_type and n != 'defaults' %}
{%-                 set props = salt['ordered.odict']() %}
{%-                 do props.update(type_defaults) %}
{%-                 do props.update(tdata) %}
{%-                 do found.update({n:props}) %}
{%-             endif %}
{%-         endfor %}
{%-     endfor %}

{%-     for n, t in found.iteritems() %}
{{sls}}.{{test_type}}.{{n}}:
    cmd.script:
        - source: salt://{{slspath}}/types/{{test_type}}-test.sh.jinja
        - template: jinja
        - context:
            ttype: '{{test_type}}'
            n: {{n}}
            t: {{t|json}}
{%-     endfor %}
{%- endif %}
