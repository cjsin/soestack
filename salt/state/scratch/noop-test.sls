{%- import 'lib/noop.sls' as noop with context %}

{{noop.notice('Notice test')}}

{{noop.warning('Warning test')}}
{{noop.error('Error test')}}
{{noop.log('Log test')}}
{{noop.pprint('Pprint test',{'a': 1,'b': { 'c': [2,3,4] } } ) }}
{%- do salt.log.error('testing jinja logging') -%}


test-multiline-name:
    noop.notice:
        - name: |
            blah line 1
            blah line 2
            blah line 3
            
test-multiline-text:
    noop.notice:
        - text: |
            blah line 1
            blah line 2
            blah line 3
            
            