{{ salt.loadtracker.load_pillar(sls,'host infra') }}

# Overrides and data for the demo test soe lan, 
# which is set up on a libvirt virtual network,
# and intended for running vagrant images with two network
# devices ( therefore the eth0 network is left for vagrant
# and the eth1 device is configured as normal)

deployments:
    ss-gitlab:
        config:
            # In my demo vm's I have very limited ram available, so need to set this down low
            # The default is that it will use 1/4 of total RAM or so
            postgres_ram: 128MB

network:
    devices:
        # Can't just ignore this device as we need to use PEERDNS=no 
        # to stop stupid NetworkManager overwriting the resolv.conf
        #eth0:
        #    ignore: True 

        eth0:
            inherit:
                - no-peerdns
                - ethernet
                - enabled
                - no-defroute
                - no-zeroconf
                - no-nm-controlled
                # Vagrant will configure this interface with dhcp
                - dhcp

        eth1:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - no-zeroconf
                - no-nm-controlled
                - infra-server
                - infra-dns

postfix:
    mode: server

layer-host-loaded: {{sls}}

