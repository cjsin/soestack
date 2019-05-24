#!stateconf yaml . jinja

.print-loaded:
    noop.pprint:
        - data: {{pillar._loaded|json}}


.print-loaded-keys:
    noop.notice:
        - text: |
            {%- for k in pillar._loaded.keys() %}
            {{k}}
            {%- endfor %}
