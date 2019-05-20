nuggets:

    pxeboot-server:
        description: |
            provides support for pxebooting clients from this node

        install:
            nuggets-required:
                - simple-http
                - tftp-server
                - dhcp-server-dnsmasq
                - iptables-firewall

            firewall-rules:
                firewall-rule-sets:
                    - dhcp-server

        activate:
            service-sets:
                enabled:
                    - dnsmasq


        filesystem:
            defaults:
                user: nobody
                group: nobody
                dir_mode: '0700'
                file_mode: '0600'

            dirs:
                /e/pxe:
                /e/pxe/pxelinux.cfg:
