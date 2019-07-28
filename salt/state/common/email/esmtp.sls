#!stateconf yaml . jinja

.installed:
    pkg.installed:
        - pkgs:
            - esmtp
            - esmtp-local-delivery
