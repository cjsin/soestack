{{ salt.loadtracker.load_pillar(sls) }}

nuggets:

    iptables-firewall:

        description: |
            provides a firewall based on iptables service scripts

        install:
            nuggets-required:
                - firewall-implementations
                
            absent:
                package-sets:
                    - firewalld-firewall

            installed:
                package-sets:
                    - iptables-firewall

        activate:
            service-sets:
                enabled:
                    - iptables-firewall
