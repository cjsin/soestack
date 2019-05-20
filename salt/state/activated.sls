#!stateconf yaml . jinja

{%- if 'activated-states' in pillar and pillar['activated-states'] %}

include:
    {%- for statepath in pillar['activated-states'] %}
    - {{statepath}}
    {%- endfor %}

{%- endif %}
