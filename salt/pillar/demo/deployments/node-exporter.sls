{{ salt.loadtracker.load_pillar(sls) }}

deployments:

    node_exporter_baremetal:
        node_exporter:
            host:      '.*'
            activated:   True
            activated_where: {{sls}}
