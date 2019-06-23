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
            config:
                hostname: gitlab.qemu
    grafana_container:
        grafana-cont:
            host:        infra
            activated:   False
            activated_where: {{sls}}
            config:
                ip:      192.168.121.108
                domain:  qemu
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
    server_ip: 192.168.121.101
    bind_user: bind-user

network:

    hostfile-additions:
        127.0.0.1:       localhost.localdomain localhost localhost4.localdomain localhost4
        '::1':           localhost6.localdomain localhost6

    classes:
        infra-server:
            sysconfig:
                # Main IP, infastructure services etc
                IPADDR1: '192.168.121.101'
                PREFIX1: '24'

                # Nginx frontend / proxy
                IPADDR2: '192.168.121.102'
                PREFIX2: '24'

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
