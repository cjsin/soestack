
{%- set blah = { 'a': { 'b': 3, 'c': 5, 'd': [ 'x','y','z'], 'e': 6 } } %}
.test-yaml-filter:
    noop.notice:
        - text: |
            {{ blah|yaml(False)|indent(12) }}

