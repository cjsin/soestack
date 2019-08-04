{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for the demo test soe lan, 
# which is set up on a libvirt virtual network,
# and intended for running vagrant images with two network
# devices ( therefore the eth0 network is left for vagrant
# and the eth1 device is configured as normal)

demo:
    vars:
        lan_name:         qemu
        soe_layers:       soe:demo,role:G@roles,site:testing,lan:qemu,host:G@host,lan-host:lan:G@layers:lan+host:G@host,private:example.private
    ips:
        gateway:          192.168.121.1
        infra-gateway-ip: 192.168.121.1

deployments:
    pxebooting:
        config:
            lans:
                defaults:
                    entries:
                        netinstall:
                            ss_settings:
                                LAYERS:    '!!demo.vars.soe_layers'
                # Extra lan for testing on 10.0.2.x
                devlan:
                    kernel:                os/dvd/images/pxeboot/vmlinuz
                    initrd:                os/dvd/images/pxeboot/initrd.img
                    iface:                 eth1
                    static:                True
                    subnet:                10.0.2
                    # entries:
                    #     # Example custom entry
                    #     custom:
                    #         title:    '^Custom Kickstart (Centos7 custom)'
                    #         ss_settings:
                    #             DOMAIN:            demo.com
                    #             ROLES:             role-set:developer-workstation-node
                    #             LAYERS:            soe:demo,site:testing,lan:custom,private:example.private
                    #         ss_hosts:
                    #             # To nodes booting within the libvirt/qemu/vagrant test network the nexus server and gateway are 10.0.2.2
                    #             192.168.121.1:     gateway gateway.demo.com
                    #             192.168.121.101:   infra.demo.com infra master salt ipa ldap nfs pxe
                    #             192.168.121.103:   nexus.demo.com nexus
                    #         append:    noquiet custom-test
                    #         kickstart: http://%http_server%/provision/kickstart/kickstart-custom.cfg
                    #         stage2:    nfs:nfsvers=4:%nfs_server%:/e/pxe/os/custom/

            hosts:
                client:
                    lan:    devlan
                    append: test-host-override

ipa-configuration:
    dns:
        reverse-zones:
            # Extra 10.0.2 network for the libvirt/qemu kickstart clients
            2.0.10.in-addr.arpa: 

network:
    hostfile-additions:
        192.168.121.1:   gateway.demo.com gateway

