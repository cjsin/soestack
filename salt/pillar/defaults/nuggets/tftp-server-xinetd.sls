
nugget_data:

    package-sets:

        tftp-server-xinetd:
            centos,rhel,fedora:
                - tftp-server
                - syslinux 
                - syslinux-tftpboot
                - xinetd

nuggets:

    tftp-server-xinetd:
        description: |
            provides a tftp server using xinetd implementation

        install:
            installed:
                package-sets:
                    - tftp-server-xinetd
            service-sets:
                enabled:
                    - xinetd
        
        filesystem:
            templates:
                {% raw %}
                xinetd_tftp_conf: |
                
                    # default: off
                    # description: The tftp server serves files using the trivial file transfer \
                    #    protocol.  The tftp protocol is often used to boot diskless \
                    #    workstations, download configuration files to network-aware printers, \
                    #    and to start the installation process for some operating systems.
                    service tftp
                    {
                        socket_type     = dgram
                        protocol        = udp
                        wait            = yes
                        user            = root
                        server          = /usr/sbin/in.tftpd
                        server_args     = -s /var/lib/tftpboot
                        disable         = {{'no' if config.enabled else 'yes'}}
                        per_source      = 11
                        cps             = 100 2
                        flags           = IPv4
                    }
                {% endraw %}

            files:
                /etc/xinetd.d/tftp:
                    template: xinetd_tftp_conf
                    config:
                        enabled: True
