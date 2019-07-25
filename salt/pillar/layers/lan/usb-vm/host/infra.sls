{{ salt.loadtracker.load_pillar(sls,'host infra') }}

_layers_test:
    lan-host:        {{sls}}
    lan-host-value:  'lan-usb-vm-host-infra'
    test_value:      'lan-usb-vm-host-infra'
    additive:
        - lan-usb-vm-host-infra


layers_test:
    lan-host:        {{sls}}
    lan-host-value:  'lan-usb-vm-host-infra'
    test_value:      'lan-usb-vm-host-infra'
    additive:
        - lan-usb-vm-host-infra

deployments:
    gitlab:
        config:
            # In my demo VM's I have very limited ram available, so need to set this down low
            # The default is that it will use 1/4 of total RAM or so
            postgres_ram: 128MB


network:
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
                - infra-server-isolated

postfix:
    mode: server

layer-host-loaded: {{sls}}

