_loaded:
    {{sls}}:

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname: gitlab.usb-phy

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.usb-phy
    nameservers:
        dns1:    127.0.0.1
        dns2:    192.168.0.1 # The wifi/modem
        dns3:    ''
    search:
        search1: usb-phy
        search2: ''
        search3: ''
        
managed-hosts:
    testenv-master:
        infra.usb-phy:
            ip:      192.168.121.101
            lan:     usb-phy
            aliases: ipa ipa.usb-phy
            type:    dns
        pxe-client1:
            ip:       192.168.121.241
            mac:      '52:54:00:96:72:f9'
            lan:      usb-phy
            type:     client
            hostfile:
                - pxe-client1
        pxe-client2:
            ip:       192.168.121.242
            mac:      '52:54:00:b9:62:3b'
            lan:      usb-phy
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       192.168.121.102
            type:     dns 
            aliases:  nginx.usb-phy nginx wildcard
        nexus:
            ip:       192.168.121.103
            type:     dns 
            # aliases:  nexus
        gitlab:
            ip:       192.168.121.104
            type:     dns 
            aliases:   gitlab
        mattermost.usb-phy:
            ip:       192.168.121.105
            type:     dns 
            aliases:  mattermost
        pages.usb-phy:
            ip:       192.168.121.106 
            type:     dns
            aliases:  pages
        gitlab-registry.usb-phy:
            ip:       192.168.121.107 
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       192.168.121.108
            type:     dns 
            aliases:  prometheus.usb-phy grafana prometheus
        kibana:
            ip:       192.168.121.109
            type:     dns 
            aliases:  elasticsearch.usb-phy kibana elasticsearch
        master:
            ip:       192.168.121.110
            type:     dns 
            aliases:  master.usb-phy master k8s.usb-phy k8s

network:
    devices:
        eth0:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - infra-server
                - infra-dns

        # example eth1 connected to external network or internet
        #eth1:
        #    inherit:
        #        - defaults
        #        - ethernet
        #        - enabled
        #        - gateway
        #        - defroute
        #        - infra-dns
        #        - home-test-environment

        # example wireless network for internet connectivity on laptop
        # note WPA is not yet successfully configured without NetworkManager.
        # For now, private WPA keys need to be included using layers.private.wpa below

        #wlan0:
        #    inherit:
        #        - defaults
        #        - wireless
        #        - enabled
        #        - gateway
        #        - defroute
        #        - infra-dns
        #        - home-test-environment

layer-host-loaded: {{sls}}


# For now the private layer files are not included, as 
# the USB provisioning has no way currently to include them

#include:
#    - layers.private.gitlab
#    - layers.private.wpa
#    - layers.private.timezone
