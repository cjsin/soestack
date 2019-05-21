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

network:
    ipv6:
        # IPA needs ipv6 enabled
        mode: 'lo-only'


rsyslog:
    server:
        enabled: True

tftp:
    implementation: dnsmasq

