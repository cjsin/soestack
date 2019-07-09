{{ salt.loadtracker.load_pillar(sls) }}

nuggets:

    dhcp-server-dnsmasq:
        description: |
            provides a dhcp server using the 'dnsmasq' implementation

        install:
            nuggets-required:
                - dhcp-server
                - iptables-firewall

            installed:
                package-sets:
                    - dnsmasq

        activate:
            service-sets:
                enabled:
                    - dnsmasq

            firewall:
                firewall-rule-sets:
                    - dhcp-server
