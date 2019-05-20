nuggets:
    firewalld-firewall:
        description: |
            provides a firewall based on firewalld

        install:
            nuggets-required:
                - firewall-implementations

            uninstalled:
                package-sets:
                    - iptables-firewall

            installed:
                package-sets:
                    - firewalld-firewall
        activate:
            service-sets:
                enabled:
                    - firewalld-firewall
