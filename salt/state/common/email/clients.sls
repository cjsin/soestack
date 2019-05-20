#!stateconf yaml . jinja

.sylpheed:
    pkg.installed:
        - pkgs:
            - sylpheed

.thunderbird:
    pkg.installed:
        - pkgs:
            - thunderbird
            - thunderbird-enigmail

.utils:
    pkg.installed:
        - pkgs:
            - xfce4-mailwatch-plugin
            - procmail
            - mailx
            - mail-notification
