{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    node-exporter:
        deploy_type:    node_exporter_baremetal
        host:           '.*'
        activated:       True
        activated_where: {{sls}}
