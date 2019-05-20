#Bullshit thunderbird is incapable of reading local mail
#So we have to use sylpheed.
#Sylpheed is so shitty it doesn't even support maildir,
# so we have to install and configure MH bullshit.

.mh-utils:
    pkg.installed:
        - pkgs:
            - nmh

/etc/skel/.mh_profile:
    file.managed:
        - contents: |
            MH-Profile-Version: 1.0
            Path: Mail

/etc/skel/.forward:
    file.managed:
        # The quoting within this line is important.
        - contents:  '| "/usr/libexec/nmh/rcvstore +inbox"'
