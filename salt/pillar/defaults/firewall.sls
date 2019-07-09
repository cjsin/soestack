{{ salt.loadtracker.load_pillar(sls) }}

# Defaults. Note this may be overridden by the security mode (security.<high|low|mid>)

firewall:
    enabled:        True
    default_policy: ACCEPT
