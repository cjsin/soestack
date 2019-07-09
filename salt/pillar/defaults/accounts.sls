{{ salt.loadtracker.load_pillar(sls) }}

accounts:

    # TODO - consider whether these should be in defaults or only in example soe 
    
    groups:

        node_exporter:
            #gid: 998

        prometheus:
            #gid: 999

        grafana:
            gid: 472

    users:

        grafana:
            fullname: Grafana Dashboard
            shell:    /bin/nologin
            uid:      472
            home:     /d/local/grafana
            groups:
                - grafana

        node_exporter:
            fullname: Node exporter
            shell:    /bin/nologin
            #uid:      998
            home:     /d/local/node_exporter
            groups:
                - node_exporter

        prometheus:
            fullname: Prometheus
            shell:    /bin/nologin
            #uid:      999
            home:     /d/local/prometheus
            groups:
                - prometheus

