{{ salt.loadtracker.load_pillar(sls) }}

selinux:
    mode:    disabled

firewall:
    enabled: True
    policy:  ACCEPT

screensaver:
    x11:
        idle-timeout: unset
        lock-timeout: unset

legal:
    banners:
        login: |
            ## NOTICE ###

            This is an example login banner for demo soe system.

            ## NOTICE ###
