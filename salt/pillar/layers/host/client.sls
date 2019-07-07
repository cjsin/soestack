{{ salt.loadtracker.load_pillar(sls,'host client') }}

network:
    hostfile-additions: {}
        # Example data
        # 192.168.121.102: wildcard.example wildcard nginx.example nginx
        
    ipv6:
        # IPA needs ipv6 enabled, but on clients it is disabled
        mode: 'disabled'

