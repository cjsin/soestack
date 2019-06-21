#!stateconf yaml . jinja

{%- set prefdir = '/usr/lib64/firefox/defaults/preferences' %}

{%- if 'firefox' in pillar and 'defaults' in pillar.firefox %}

{{sls}}.defaults:
    file.managed:
        - name: {{prefdir}}/all-0-soestack.js
        - contents_pillar: firefox:defaults
        - onlyif: test -d '{{prefdir}}'

{%- endif %}
