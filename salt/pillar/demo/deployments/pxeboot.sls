{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    pxeboot_server:
        soestack_demo:
            host:      infra
            activated: True
            activated_where: {{sls}}

            activate:

                service-sets:
                    enabled:
                        - pxeboot-server

                services:
                    enabled:
                        - simple-http-pxe

                firewall:
                    basic:
                        pxebooting:
                            ip: 192.168.121.101
                            accept:
                                udp:
                                    dhcp: 67:69

            config:
                clients:
                    - pxe-client1
                    - pxe-client2
                    - client

                isos:
                    #netinstall: CentOS-7-x86_64-NetInstall-1810.iso
                    minimal:     CentOS-7-x86_64-Minimal-1810.iso
                    #everything:  CentOS-7-x86_64-Everything-1810.iso
                    dvd:         CentOS-7-x86_64-DVD-1810.iso

                paths:                
                    tftp:  /e/pxe
                    pxe:   ''
                    cfgs:  pxelinux.cfg
                    nfs:   /e/pxe
                    os:    os
                    isos:  /e/iso
                
                hostdata:            managed-hosts:testenv-master
                server:              '192.168.121.101'
                nfs_server:          '192.168.121.101'
                http_server:         '192.168.121.101:9001'

                provisioning:
                    scripts:  /soestack/provision/
                    pw:
                        # default passwords are 'password'. These should be changed before deployment using 'openssl passwd -1' and 'grub2-mkpasswd-pbkdf2'
                        root: $1$CQhozIp2$9tY0XzTSDJybkrvsbHiaZ/
                        ssh:  $1$CQhozIp2$9tY0XzTSDJybkrvsbHiaZ/
                        grub: grub.pbkdf2.sha512.10000.1C11D162AB8114362039617C2D4729E60D2FA57572974E9BB4B60B496F5D8E105D87E4114763A2DCD7DF451E5653C68C05A90595A48D3217D8B5A61DF0DA2198.B1C27FE16CCF44335EA9D2942009B30F2BB4EC760AEFD3AFC515F2A778D71D14A56E229DFAE5B79B2A3F1B0A5FA96B771661E37FD6640DB1A5F3D23C5F7446BE

                lans:
                    defaults:
                        timeout:       600
                        title:         'Default Network Boot'
                        type:          'soestack'
                        kernel:        os/minimal/images/pxeboot/vmlinuz
                        initrd:        os/minimal/images/pxeboot/initrd.img
                        ss_provisioning: os/minimal/provision
                        nfs_server:    '192.168.121.101'
                        http_server:   '192.168.121.101:9001'
                        append:
                            - rd.shell ip=dhcp inst.sshd=1
                        entries:
                            localboot-1:
                                title: '^Continue normal boot'
                                # example entry which does not do a network boot
                                type:   custom
                                initrd: ''
                                kernel: ''
                                append: ''
                                custom: |
                                    LOCALBOOT -1
                            # localboot80:
                            #     title: '^Boot from Hard Disk (0x80)'
                            #     # example entry which does not do a network boo
                            #     type:   custom
                            #     initrd: ''
                            #     kernel: ''
                            #     append: ''
                            #     custom: |
                            #         LOCALBOOT 0x80
                            netinstall:
                                title:  '^Network Install (Centos7)'
                                type:   soestack
                                # NOTE: specifying a compatible type for appending (a list, here)
                                # will add the '-noquiet' to the 'rd.shell' specified in 'append' in the defaults above.
                                # But specifying an incompatible type - such as a plain string, will replace the defaults and start
                                # anew with just this setting
                                append: 
                                    - noquiet
                                    - modprobe.blacklist=xfs
                                    - rd.driver.blacklist=xfs
                                # For example, this would set the kernel commandline appends to just 'noquiet', discarding the 'rd.shell' specified above
                                #append: noquiet 
                                ss_settings:
                                    BOOTSTRAP_REPOS:   bootstrap-centos.repo
                                    #WAIT:              1
                                    DOMAIN:            default
                                    SALT_MASTER:       infra.default
                                    # NOTE that the admin email is mandatory for having a working Salt/GPG integration
                                    # for private data storage
                                    ADMIN_EMAIL:       admin@demo.soestack.example.com
                                    SALT_TYPE:         minion
                                    NAMESERVER:        192.168.121.101
                                    ROLES:             basic-node
                                    LAYERS:            soe:demo,site:testing,lan:default,private:example
                                    DEVELOPMENT:       0
                                    INTERACTIVE:       0
                                    WAIT:              0
                                    INSPECT:           0
                                    SKIP_CONFIRMATION: 0
                                    #BOOTSTRAP_REPOS:   bootstrap-centos.repo
                                    NEXUS:             nexus:7081
                                    TIMEZONE:          UTC
                                ss_repos:
                                    os:                'http://$NEXUS/repository/centos/centos/$releaselong/os/$basearch'
                                    updates:           'http://$NEXUS/repository/centos/centos/$releaselong/updates/$basearch'
                                ss_hosts: {}
                                kickstart: http://%http_server%/os/minimal/provision/kickstart/kickstart.cfg
                                stage2:    nfs:%nfs_server%:/e/pxe/os/minimal/

