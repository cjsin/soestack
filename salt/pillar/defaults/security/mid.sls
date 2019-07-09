{{ salt.loadtracker.load_pillar(sls) }}

selinux:
    mode:    permissive

firewall:
    enabled: True
    policy:  LOG

screensaver:
    x11:
        idle-timeout: 600
        lock-timeout: 600

legal:
    banners:
        login: |
            Hey please don't do anything nasty on this system.
