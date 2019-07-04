# Overrides for the testing site

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

deployments:
    dovecot_server:
        dovecot:
            host:        infra
            activated:   True
            activated_where: {{sls}}
    elasticsearch_container:
        elasticsearch-testdev:
            host:        infra
            activated:   False
            activated_where: {{sls}}
    gitlab_runner_baremetal:
        gitlab-runner:
            host:        infra
            activated:   False
            activated_where: {{sls}}
    gitlab_baremetal:
        gitlab:
            host:        infra
            activated:   False
            activated_where: {{sls}}
    grafana_container:
        grafana-cont:
            host:        infra
            activated:   True
            activated_where: {{sls}}
            config:
                ip:      192.168.121.108
                domain:  demo.com
    ipa_client:
        testenv-client:
            config:
                site:    testing
    ipa_master:
        testenv-master:
            config:
                passwords:
                    master: master123
                    admin:  admin123
                    ds:     random
                site:   testing
                initial-setup:
                    automount:
                        locations:
                            - testing
    kibana_container:
        kibana-frontend:
            host:        infra
            activated:   False
            activated_where: {{sls}}
    logstash_baremetal:
        logstash-sys:
            host:        infra
            activated:   False
            activated_where: {{sls}}
    nexus_container:
        nexus-mirror:
            host:        infra
            activated:   True
            activated_where: {{sls}}
    phpldapadmin_baremetal:
        phpldapadmin:
            host:        infra
            activated:   False
            activated_where: {{sls}}
    prometheus_container:
        prometheus-server:
            host:        infra
            activated:   False
            activated_where: {{sls}}

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
            # This will be set per-lan (in the lan layer)
            dns: []
            #dns-opts:
            #    #- 'ndots:0'
            dns-search:
                - demo
            
            # disable-legacy-registry: True


ipa:
    server_ip: 192.168.121.101
    bind_user: bind-user

network:

    hostfile-additions:
        127.0.0.1:       localhost.localdomain localhost localhost4.localdomain localhost4
        '::1':           localhost6.localdomain localhost6

    classes:
        infra-server-common:
            sysconfig:
                # Nexus
                IPADDR3: '192.168.121.103'
                PREFIX3: '24'

                # Gitlab
                IPADDR4: '192.168.121.104'
                PREFIX4: '24'

                # Gitlab mattermost
                IPADDR5: '192.168.121.105'
                PREFIX5: '24'

                # Gitlab pages
                IPADDR6: '192.168.121.106'
                PREFIX6: '24'

                # Gitlab docker registry
                IPADDR7: '192.168.121.107'
                PREFIX7: '24'

                # Grafana and Prometheus
                IPADDR8: '192.168.121.108'
                PREFIX8: '24'

                # Elasticsearch and Kibana
                IPADDR9: '192.168.121.109'
                PREFIX9: '24'

                # Kubernetes master
                IPADDR10: '192.168.121.110'
                PREFIX10: '24'

                # SOEStack docs
                IPADDR11: '192.168.121.111'
                PREFIX11: '24'
        infra-server-netconnected:
            sysconfig:
                # An net-connected server will set the IP address for the gateway on IPADDR2,
                # and the 121.101 address for IPADDR2
                # and the nginx one (currently unused) will be moved to IPADDR12
                # This is because we desire the IP address that can communicate to the gateway,
                # to be the first one on the interface.
                # Nginx frontend / proxy
                IPADDR12: '192.168.121.102'
                PREFIX12: '24'
        infra-server-isolated:
            sysconfig:
                # An isolated server will set the x.x.121.101 address for IPADDR1
                # and the nginx one (currently unused) will be slotted onto IPADDR2
                # Main IP, infastructure services etc
                IPADDR1: '192.168.121.101'
                PREFIX1: '24'
                # Nginx frontend / proxy
                IPADDR2: '192.168.121.102'
                PREFIX2: '24'

