{{ salt.loadtracker.load_pillar(sls) }}

service-reg: {}
    # Example of setting service addresses on your lan for using
    # within configuration templates or states:

    # nexus_http:    nexus:7081
    # nexus_docker:  nexus:7082
    # gitlab_http:   gitlab:8000
    # gitlab_docker: gitlab:5005
    # prometheus:    prometheus:9090
    # grafana:       grafana:7070
    # ipa_https:     infra:443
