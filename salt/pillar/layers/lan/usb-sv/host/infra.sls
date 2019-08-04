{{ salt.loadtracker.load_pillar(sls,'host infra') }}

network:
    classes:
        # On this network we rearrange the order of IP address assignment
        # so that the gateway to the internet has the first IP address
        # because it's a modem and can't do routing from our other subnet
        infra-server-netconnected:
            sysconfig:
                # IP for Gateway subnet
                IPADDR1: '!!demo.ips.infra-gateway-ip'
                PREFIX1: '24'
                # Main infra services
                IPADDR2: '!!demo.ips.infra'
                PREFIX2: '24'
    devices:
        # Can't just ignore this device as we need to use PEERDNS=no 
        # to stop stupid NetworkManager overwriting the resolv.conf
        #eth0:
        #    ignore: True 
        # eth0:
        #     inherit:
        #         - no-peerdns
        #         - ethernet
        #         - enabled
        #         - no-defroute
        #         - dhcp
        #         - no-nm-controlled

        eth0:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - infra-dns
                - infra-server-common
                - infra-server-netconnected

postfix:
    mode: server

layer-host-loaded: {{sls}}
