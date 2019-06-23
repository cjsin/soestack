_loaded:
    {{sls}}:

deployments:
    gitlab_baremetal:
        gitlab:
            config:
                hostname:     gitlab.demo.usb-vm
                # In my demo VM's I have very limited ram available, so need to set this down low
                # The default is that it will use 1/4 of total RAM or so
                postgres_ram: 128MB
    ipa_master:
        testenv-master:
            config:
                passwords:
                    master: master123
                    admin:  admin123
                    ds:     random

# Override DNS on the infra server
dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo.usb-vm
    nameservers:
        dns1:    127.0.0.1
        dns2:    192.168.121.1 # The VM host
        dns3:    ''
    search:
        search1: demo.usb-vm
        search2: ''
        search3: ''
        
managed-hosts:
    testenv-master:
        infra.demo.usb-vm:
            ip:      192.168.121.101
            lan:     usb-vm
            aliases: ipa
            type:    dns

        pxe-client1:
            ip:       192.168.121.241
            mac:      '52:54:00:96:72:f9'
            lan:      usb-vm
            type:     client
            hostfile:
                - pxe-client1
        pxe-client2:
            ip:       192.168.121.242
            mac:      '52:54:00:b9:b8:d2'
            lan:      usb-vm
            type:     client
            hostfile:
                - pxe-client2
        wildcard:
            ip:       192.168.121.102
            type:     dns 
            aliases:  nginx.demo.usb-vm nginx wildcard
        nexus:
            ip:       192.168.121.103
            type:     dns 
            # aliases:  nexus
        gitlab:
            ip:       192.168.121.104
            type:     dns 
            aliases:   gitlab.demo.usb-vm
        mattermost.demo.usb-vm:
            ip:       192.168.121.105
            type:     dns 
            aliases:  mattermost
        pages.demo.usb-vm:
            ip:       192.168.121.106 
            type:     dns
            aliases:  pages
        gitlab-registry.demo.usb-vm:
            ip:       192.168.121.107 
            type:     dns
            aliases:  gitlab-registry
        grafana:
            ip:       192.168.121.108
            type:     dns 
            aliases:  prometheus.demo.usb-vm grafana prometheus
        kibana:
            ip:       192.168.121.109
            type:     dns 
            aliases:  elasticsearch.demo.usb-vm kibana elasticsearch
        master:
            ip:       192.168.121.110
            type:     dns 
            aliases:  master.demo.usb-vm master k8s.demo.usb-vm k8s
        docs:
            ip:       192.168.121.111
            type:     dns 
            aliases:  docs.demo.usb-vm docs

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
                - infra-server
                - infra-dns

postfix:
    config:
        inet_interfaces:  192.168.121.101
        mydomain:         usb-vm
        #myorigin:         demo.usb-vm
        myorigin:         usb-vm
        mydestination:    $myhostname, $mydomain, localhost.$mydomain, localhost.localdomain, localhost
        home_mailbox:     Maildir/
        relayhost:        ''
        relay_domains:    ''

layer-host-loaded: {{sls}}


# For now the private layer files are not included, as 
# the USB provisioning has no way currently to include them

#include:
#    - layers.private.gitlab
#    - layers.private.timezone
