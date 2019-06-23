#!stateconf yaml . jinja

.installed:
    pkg.installed:
        - pkgs:
            - alpine

.etc-defaults:
    file.managed:
        - name:   /etc/pine.conf
        - contents: ''
        - require:
            - pkg: {{sls}}::installed
