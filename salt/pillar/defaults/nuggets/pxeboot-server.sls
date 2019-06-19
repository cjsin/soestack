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

            files:
                /etc/exports.d/0-toplevel.exports:
                    mode: '0644'
                    contents: |
                        /e     *(ro,async,root_squash,fsid=0)

                /etc/exports.d/50-home.exports:
                    mode: '0644'
                    contents: |
                        /e/home *(rw,async,root_squash)
                    
                /etc/exports.d/99-pxe.exports:
                    file_mode: '0644'
                    contents: |
                        /e/pxe *(ro,async,root_squash)
                    

            dirs:
                /e/home:
                    user:  root
                    group: root
                    mode: '0755'

                /e/pxe:
                    description: Export home directories for clients
                    user:   root
                    group:  root
                    mode:   '0755'
                    dir_mode:   '0755'
                    mkdirs: True

                /e/pxe/pxelinux.cfg:
                    mode:   '0755'
                    dir_mode:   '0755'
