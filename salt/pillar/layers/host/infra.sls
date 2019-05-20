_loaded:
    {{sls}}:

nexus-repos:
    defaults:
        gitlab:   True # add only on the infra server

include:
    - demo.deployments.elasticsearch
    - demo.deployments.gitlab-runner
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.ipa-master
    - demo.deployments.kibana
    - demo.deployments.kube-master
    - demo.deployments.logstash-sys
    - demo.deployments.logstash-user
    - demo.deployments.nexus-mirror
    - demo.deployments.nginx-reverse-proxy
    - demo.deployments.phpldapadmin
    - demo.deployments.prometheus
    - demo.deployments.pxeboot
    - demo.deployments.simple-http-pxe
    
dhcp:

    dnsmasq:
        enabled: True
        dhcp_only: True 
        range:
            - 192.168.1.20
            - 192.168.1.30
    
        # 8640m is 6 days
        lease_time: 8640

    dhcpd:
        enabled: False
        # 8640m is 6 days
        lease_time: 8640
        subnets:    
            192.168.1.0:
                routers: 192.168.1.1
                netmask: 255.255.255.0

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo
    nameservers:
        dns1:    127.0.0.1
        dns2:    192.168.188.1
    search:
        search1: gateway
        search2: demo

network:
        
    # Just until IPA is configured to add these.
    #hostfile-additions:
    #    192.168.121.102: wildcard.demo wildcard prometheus.demo prometheus grafana.demo grafana 
    #    192.168.121.103: gitlab.demo gitlab pages.demo pages mattermost.demo mattermost
    devices:
        # Note, in this configuration, eth0 is used for Vagrant,
        # so it is not modified.
        
        #eth0:
        #    delete: True 

        wlan0:
            sysconfig: |
                TYPE=Wireless
                WPA="yes"
                KEY_MGMT=WPA-PSK
                #MODE=Managed
                ONBOOT=yes
                DEFROUTE=yes
                GATEWAY=192.168.188.1
                BOOTPROTO=dhcp
                ONBOOT=yes
                PEERDNS=no
                PEERROUTES=no
                DEFROUTE=no
                PROXY_METHOD=none
                BROWSER_ONLY=no
                DEFROUTE=yes
                IPV4_FAILURE_FATAL=no
                IPV6INIT=no
                IPV6_AUTOCONF=no
                IPV6_DEFROUTE=no
                IPV6_FAILURE_FATAL=no
                IPV6_ADDR_GEN_MODE=stable-privacy
                NM_CONTROLLED=no
            wpa: |
                network={
                    ssid=EXAMPLE
                    scan_ssid=1
                    key_mgmt=WPA-PSK
                    psk=big_long_example_wpa_psk_value
                }

        eth0:
            sysconfig: |
                IPADDR1=192.168.121.101
                PREFIX1=24

                IPADDR2=192.168.121.102
                PREFIX2=24

                IPADDR3=192.168.121.103
                PREFIX3=24

                IPADDR4=192.168.121.104
                PREFIX4=24

                IPADDR5=192.168.121.105
                PREFIX5=24

                IPADDR6=192.168.121.106
                PREFIX6=24

                IPADDR7=192.168.121.107
                PREFIX7=24

                IPADDR8=192.168.121.108
                PREFIX8=24

                IPADDR9=192.168.121.109
                PREFIX9=24

                IPADDR10=192.168.121.110
                PREFIX10=24

                #GATEWAY=192.168.121.1
                # wifi gateway
                GATEWAY=192.168.188.1
                ONBOOT=yes
                PEERDNS=no
                BOOTPROTO=none
                PEERROUTES=no
                DEFROUTE=no
                TYPE=Ethernet
                PROXY_METHOD=none
                BROWSER_ONLY=no
                DEFROUTE=no
                IPV4_FAILURE_FATAL=no
                IPV6INIT=no
                IPV6_AUTOCONF=no
                IPV6_DEFROUTE=no
                IPV6_FAILURE_FATAL=no
                IPV6_ADDR_GEN_MODE=stable-privacy
                NM_CONTROLLED=no


    ipv6:
        # IPA needs ipv6 enabled
        mode: 'lo-only'


rsyslog:
    server:
        enabled: True

tftp:
    implementation: dnsmasq

