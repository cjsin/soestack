selinux:
    mode:    enforcing

firewall:
    enabled: True
    policy:  LOG,REJECT

screensaver:
    x11:
        idle-timeout: 300
        lock-timeout: 300

legal:
    banners:
        login: |
            ## NOTICE ###

            Activity on this system is logged. 
            
            We know what you are going to do before you do it, Minority-Report style.

            Plus remember you won't get any Christmas presents if you do bad things.
            
            ## NOTICE ###
