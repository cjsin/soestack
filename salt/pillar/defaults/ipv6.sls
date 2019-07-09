{{ salt.loadtracker.load_pillar(sls) }}

network:
    ipv6:
        # Valid modes: enabled,disabled,lo-only
        mode: disabled
