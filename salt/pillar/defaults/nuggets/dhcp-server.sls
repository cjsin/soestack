{{ salt.loadtracker.load_pillar(sls) }}

nugget_data:
    firewall:
        dhcp-server:
            complex:
                allow_dhcp:
                    table:     filter
                    chain:     INPUT
                    jump:      ACCEPT
                    match:     state
                    connstate: NEW
                    dport:     67
                    protocol:  udp
                    sport:     68


nuggets:
    dhcp-server:
        description: |
            provides common data for deploying a dhcp server

        # A specific implementation will add more

