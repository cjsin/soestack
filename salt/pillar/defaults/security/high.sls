{{ salt.loadtracker.load_pillar(sls) }}

selinux:
    mode:    enforcing

firewall:
    enabled: True
    policy:  REJECT

screensaver:
    x11:
        idle-timeout: 900
        lock-timeout: 900

legal:
    banners:
        login: |
            ## NOTICE###

            Activity on this system is logged.
            
            Any breaking of the laws or acceptable use policy will be prosecuted.
            
            ## NOTICE###



