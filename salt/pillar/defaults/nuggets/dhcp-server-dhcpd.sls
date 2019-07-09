{{ salt.loadtracker.load_pillar(sls) }}

nugget_data:

    package-sets:

        dhcp-server-dhcpd:
            centos,rhel,fedora:
                - dhcp

    service-sets:
        dhcp-server-dhcpd:
            centos,rhel,fedora:
                - dhcpd

nuggets:
    dhcp-server-dhcpd:
        description: |
            provides a dhcp server using the 'dhcpd' implementation

        install:
            nuggets-required:
                - dhcp-server
                - iptables-firewall

            installed:
                package-sets:
                    - dhcp-server-dhcpd

        activate:
            service-sets:
                enabled:
                    - dhcp-server-dhcpd

            firewall:
                firewall-rule-sets:
                    - dhcp-server
