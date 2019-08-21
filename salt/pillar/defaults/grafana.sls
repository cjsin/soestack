{{ salt.loadtracker.load_pillar(sls) }}

firewall:
    ss-grafana:
        basic:
            accept:
                tcp:
                    http-frontend: 7070

# This may be obsolete due to grafana_container deployment
grafana:
    port:    7070
    user:    grafana
    group:   grafana
