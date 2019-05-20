#!stateconf yaml . jinja

.postfix:
    pkg.installed:
        - pkgs:
            - postfix
            - postfix-perl-scripts

