#!stateconf yaml . jinja

.print-pillar:
    noop.pprint:
        - data: {{pillar|json}}
