include:
    # Some managed_hosts states will fail the first time
    # the server is installed because IPA won't have been
    # installed yet.
    # However it still needs to be run early, to ensure the
    # host file is updated appropriately
    - .managed_hosts

    # NOTE the order of these is important, because for example
    # IPA will fail to install if Gitlab is running and using port 80,
    # even bound with a different IP - since IPA attempts to bind using 0.0.0.0 (with httpd)
    # at instalation time.

    # nexus container is first deployed by the infra server setup script
    # but is updated by this deployment
    - .nexus_container

    - .ipa.master
    - .ipa.client

    # Simple python http services for various functions
    # (including the pxeboot service deployed after)
    - .simple_http

    # Infrastructure support for building clients over the network
    - .pxeboot_server

    ## Temporarily disabling these deployments for easier debugging
    {%- if False %}
    ## of initial USB install
    # Monitoring metrics
    - .node_exporter_baremetal
    # Monitoring server
    - .prometheus_container
    # Monitoring dashboard
    - .grafana_baremetal
    - .grafana_container

    # - .nginx

    # Git repos
    ##- .gitlab_baremetal
    {%- endif %}

    # Logging server
    ## - .elasticsearch_container

    # Logging frontend dashboard
    # kibana is failing to pull docker image from elastic.co
    ## - .kibana_container
    # - .kibana_baremetal

    # Logging client support
    # logstash is failing to pull docker image from useless elastic.co
    ## - .logstash_container
    ## - .logstash_baremetal

    # Kubernetes cluster
    ## - .kube_master
