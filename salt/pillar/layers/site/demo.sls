# Overrides for the demo test soe site

_loaded:
  {{sls}}:

include:
    - demo.deployments.ipa-master
    - demo.deployments.managed-hosts
    - demo.deployments.node-exporter
    - demo.hosts

cups:
    listen_address: 0.0.0.0:631

    management_hosts:
        - host.demo 

    printer_default:   example-printer
    printers:
        example-printer:
            uuid:      b11e07ba-8101-4d3d-835e-0d36891faddd
            info:      Example printer
            makemodel: Example printer (recommended)
            ip:        192.168.121.215


docker:
    config:
        daemon:
            insecure-registries:
                # docker-ce
                - nexus:7082
                # elasticco
                - nexus:7083
                # k8s.gcr.io
                - nexus:7084
                # unused
                # Misc (uploaded manually)
                - nexus:7085
                - gitlab-registry.demo:5000
            dns: 
                - 192.168.188.1   # modem / gateway in test environment
                - 192.168.121.101 # infra server
            #dns-opts:
            #    #- 'ndots:0'
            dns-search:
                - demo

            # disable-legacy-registry: True


ipa:
    base_dn:   dc=demo
    server_ip: 192.168.121.101
    bind_user: bind-user

network:

    hostfile-additions:
        127.0.0.1:       localhost.localdomain localhost localhost4.localdomain localhost4
        '::1':           localhost6.localdomain localhost6
        # For now use the nexus on my host box to avoid re-downloading anything
        192.168.121.1:   wired-gateway
        
        192.168.188.1:   gateway modem 

    system_domain: demo

dns:
    # if is_server is set, the server will have a customised dns configuration
    server:      infra.demo
    nameservers:
        dns1:    192.168.121.101
        dns2:    192.168.188.1
    search:
        search1: gateway
        search2: demo

node_lists:
    prometheus:
        primary:
            - infra
        secondary:
            - pxe-client
            - pxe-client2
            - usbboot
        workstations: []

npm:
    host_config:
        registry:     http://nexus:7081/repository/npmjs/

pip:
    host_config: |
        [global]
        index        = http://nexus:7081/repository/pypi/pypi
        index-url    = http://nexus:7081/repository/pypi/simple
        no-cache-dir = false
        trusted-host = nexus
        disable-pip-version-check = True

        [list]
        format = columns


rsyslog:
    client:
        send:
            192.168.121.101:
                port:     2514
                protocol: relp

service-reg:
    nexus_http:    nexus:7081
    nexus_docker:  nexus:7082
    default_registry: nexus:7082
    gitlab_http:   gitlab
    gitlab_docker: gitlab-registry:5005
    prometheus:    prometheus:9090
    grafana:       grafana:7070
    ipa_https:     infra:443
    nginx_http:    192.168.121.102:80
    nginx_https:   192.168.121.102:443

email:
    aliases:
        root: devuser

 
timezone: UTC

