include:
    - .managed_hosts

    # nexus container is first deployed by the infra server setup script
    # but is updated by this deployment
    - .nexus_container

    # Logging server
    - .elasticsearch_container

    # Git repos
    - .gitlab_baremetal

    # Monitoring dashboard
    - .grafana_baremetal
    - .grafana_container

    - .ipa.master
    - .ipa.client

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
