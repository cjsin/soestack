#!stateconf yaml . jinja

.deps:
    pkg.installed:
        - pkgs:
            - mailcap
            - hunspell

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
