{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for testing a USB build in a virtual machine (using a qemu virtual machine network)

demo:
    vars:
        lan_name:         usb-sv
        layers:           soe:demo,site:testing,lan:usb-sv,private:example.private
    ips:
        gateway:          192.168.0.1
        infra-gateway-ip: 192.168.0.101

deployments:
    pxebooting:
        config:
            lans:
                defaults:
                    entries:
                        netinstall:
                            ss_hosts:
                                192.168.0.1:       gateway.demo.com gateway

network:

    hostfile-additions:
        192.168.0.1:     gateway.demo.com gateway
