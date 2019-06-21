_loaded:
    {{sls}}:


# Overrides and data for the demo test soe lan, 
# which is set up on a libvirt virtual network,
# and intended for running vagrant images with two network
# devices ( therefore the eth0 network is left for vagrant
# and the eth1 device is configured as normal)

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname: gitlab.qemu
                # In my demo vm's I have very limited ram available, so need to set this down low
                # The default is that it will use 1/4 of total RAM or so
                postgres_ram: 128MB

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.qemu
    nameservers:
        dns1:    127.0.0.1
        dns2:    192.168.121.1 # The VM host
        dns3:    ''
    search:
        search1: qemu
        search2: ''
        search3: ''
        
managed-hosts:
    testenv-master:
        infra.qemu:
            ip:      192.168.121.101
            lan:     qemu
            aliases: ipa ipa.qemu
            type:    dns
        pxe-client1:
            ip:       192.168.121.241
            mac:      '52:54:00:96:72:f9'
            lan:      qemu
            type:     client
            hostfile:
                - pxe-client1
        pxe-client2:
            ip:       192.168.121.242
            mac:      '52:54:00:b9:62:3b'
            lan:      qemu
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       192.168.121.102
            type:     dns 
            aliases:  nginx.qemu nginx wildcard
        nexus:
            ip:       192.168.121.103
            type:     dns 
            # aliases:  nexus
        gitlab:
            ip:       192.168.121.104
            type:     dns 
            aliases:   gitlab
        mattermost.qemu:
            ip:       192.168.121.105
            type:     dns 
            aliases:  mattermost
        pages.qemu:
            ip:       192.168.121.106 
            type:     dns
            aliases:  pages
        gitlab-registry.qemu:
            ip:       192.168.121.107 
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       192.168.121.108
            type:     dns 
            aliases:  prometheus.qemu grafana prometheus
        kibana:
            ip:       192.168.121.109
            type:     dns 
            aliases:  elasticsearch.qemu kibana elasticsearch
        master:
            ip:       192.168.121.110
            type:     dns 
            aliases:  master.qemu master k8s.qemu k8s

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

layer-host-loaded: {{sls}}


# For now the private layer files are not included, as 
# the USB provisioning has no way currently to include them

#include:
#    - layers.private.gitlab
#    - layers.private.timezone
