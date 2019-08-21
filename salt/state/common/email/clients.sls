#!stateconf yaml . jinja

#.sylpheed:
#    pkg.installed:
#        - pkgs:
#            - sylpheed

include:
    - .thunderbird
    # alpine needs epel repo which is currently broken
    - .alpine
    # no nmh available without working epel repos (disabled till nexus bugfix)
    - .mh
    - .mutt

.utils:
    pkg.installed:
        - pkgs:
            # - xfce4-mailwatch-plugin
            - procmail
            - mailx
            # - mail-notification

