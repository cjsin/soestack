#!stateconf yaml . jinja

.installed:
    pkg.installed:
        - fromrepo: epel
        - pkgs:
            - alpine

.etc-defaults:
    file.managed:
        - name:   /etc/pine.conf
        - contents: ''
        - require:
            - pkg: {{sls}}::installed
