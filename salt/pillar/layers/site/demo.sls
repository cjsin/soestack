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
        - infra

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
                - gitlab-registry:5000
            dns: 
                - 192.168.121.1   # host in VM environment
                # - 192.168.188.1   # modem / gateway in test environment
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

    classes:
        infra-server:
            sysconfig:
                IPADDR1: '192.168.121.101'
                PREFIX1: '24'

                IPADDR2: '192.168.121.102'
                PREFIX2: '24'

                IPADDR3: '192.168.121.103'
                PREFIX3: '24'

                IPADDR4: '192.168.121.104'
                PREFIX4: '24'

                IPADDR5: '192.168.121.105'
                PREFIX5: '24'

                IPADDR6: '192.168.121.106'
                PREFIX6: '24'

                IPADDR7: '192.168.121.107'
                PREFIX7: '24'

                IPADDR8: '192.168.121.108'
                PREFIX8: '24'

                IPADDR9: '192.168.121.109'
                PREFIX9: '24'

                IPADDR10: '192.168.121.110'
                PREFIX10: '24'        