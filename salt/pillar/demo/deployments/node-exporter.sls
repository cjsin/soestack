_loaded:
    {{sls}}:

deployments:

    node_exporter_baremetal:
        node_exporter:
            host:      '.*'
            activated:   True
            activated_where: {{sls}}
