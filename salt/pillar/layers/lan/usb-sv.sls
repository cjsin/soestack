{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for testing a USB build in a virtual machine (using a qemu virtual machine network)

demo:
    vars:
        lan_name:         usb-sv
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
                            ss_settings:
                                LAYERS:            soe:demo,role:G@roles,site:testing,lan:usb-sv,host:G@host,lan-host:lan:G@layers:lan+host:G@host,private:example.private
                            ss_hosts:
                                192.168.0.1:       gateway.demo.com gateway

network:

    hostfile-additions:
        192.168.0.1:     gateway.demo.com gateway

    classes:
        gateway:
            sysconfig:
                GATEWAY: '!!demo.ips.gateway'
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: '!!demo.ips.gateway'
                DNS3: ''
        infra-server-netconnected:
            sysconfig:
                # IP for Gateway subnet
                IPADDR1: '!!demo.ips.infra-gateway-ip'
                PREFIX1: '24'
                # Main infra services
                IPADDR2: '!!demo.ips.infra'
                PREFIX2: '24'
