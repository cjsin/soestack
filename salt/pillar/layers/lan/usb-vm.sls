{{ salt.loadtracker.load_pillar(sls) }}

# Overrides and data for testing a USB build in a virtual machine (using a qemu virtual machine network)
_layers_test:
    lan:        {{sls}}
    lan_value:  'lan-usb-vm'
    test_value: 'lan-usb-vm'
    additive:
        - lan-usb-vm

layers_test:
    lan:        {{sls}}
    lan_value:  'lan-usb-vm'
    test_value: 'lan-usb-vm'
    additive:
        - lan-usb-vm

demo:
    vars:
        lan_name:         usb-vm
    ips:
        gateway:          192.168.121.1
        infra-gateway-ip: 192.168.121.1
    macs:
        infra:            '52:54:00:d5:19:d5'
        replica1:         '52:54:00:96:72:f9'
        processor2:       '52:54:00:b9:b8:d2'
        workstation3:     '52:54:00:00:01:03'

deployments:
    pxebooting:
        config:
            lans:
                defaults:
                    entries:
                        netinstall:
                            ss_settings:
                                LAYERS:            soe:demo,site:testing,lan:usb-vm,private:example.private
                            ss_hosts:
                                192.168.121.1:     gateway.demo.com gateway

network:
    
    hostfile-additions:
        192.168.121.1:   gateway.demo.com gateway

    classes:
        gateway:
            sysconfig:
                GATEWAY: '!!demo.ips.gateway'
        infra-dns:
            sysconfig:
                DNS1: 127.0.0.1
                DNS2: '!!demo.ips.gateway'
                DNS3: ''
