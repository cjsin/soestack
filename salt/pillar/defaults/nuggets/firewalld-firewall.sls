{{ salt.loadtracker.load_pillar(sls) }}

nuggets:
    firewalld-firewall:
        description: |
            provides a firewall based on firewalld

        install:
            nuggets-required:
                - firewall-implementations

            absent:
                package-sets:
                    - iptables-firewall

            installed:
                package-sets:
                    - firewalld-firewall
        activate:
            service-sets:
                enabled:
                    - firewalld-firewall
