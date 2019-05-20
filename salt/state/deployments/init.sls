include:
    - .managed_hosts

    # Logging server
    - .elasticsearch_container

    # Git repos
    - .gitlab_baremetal

    # Monitoring dashboard
    - .grafana_baremetal
    - .grafana_container

    - .ipa.master
    - .ipa.client

    # nexus container is instead deployed by the infra server setup script
    # - .nexus_container
    # - .nginx

    # Monitoring server
    - .prometheus_container
    # Monitoring metrics
    - .node_exporter_baremetal

    # Logging client support
    # logstash is failing to pull docker image from useless elastic.co
    - .logstash_container
    - .logstash_baremetal

    # Kubernetes cluster
    - .kube_master

    # Logging frontend dashboard
    # kibana is failing to pull docker image from elastic.co
    - .kibana_container
    # - .kibana_baremetal

    # Infrastructure support for building clients over the network
    - .pxeboot_server
    - .simple_http
