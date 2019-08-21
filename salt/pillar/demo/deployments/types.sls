
deployment-types:
    defaults:
        isa: nugget
        impl: templates.deployment.%

    # The main fallback superclass, (a) top of the hierarchy
    nugget:
        isa:  ''

    # Services which use nugget deployment but also have customised implementation
    # and a directory for files, templates etc
    kube_master: 
        isa: nugget
        impl: templates.deployment.%.%
    logstash_baremetal: 
        isa: nugget
        impl: templates.deployment.%.%
    phpldapadmin_baremetal: 
        isa: nugget
        impl: templates.deployment.%.%
    gitlab_runner_baremetal: 
        isa: nugget
        impl: templates.deployment.%.%
    ipa: 
        isa: nugget
        impl: templates.deployment.%.%
    gitlab_baremetal: 
        isa: nugget
        impl: templates.deployment.%.%

    # Services which use nugget deployment but also have customised implementation
    containerized_service: 
        isa: nugget
        impl: templates.deployment.%.%
    managed_hosts: 
        isa: nugget
    simple_http: 
        isa: nugget
    pgp_keyserver: 
        isa: nugget
    kube_node:
        isa: nugget
    node_exporter_baremetal: 
        isa: nugget
    pxeboot_server: 
        isa: nugget
        impl: templates.deployment.%.%
    kibana_baremetal: 
        isa: nugget
    grafana_baremetal: 
        isa: nugget
        impl: templates.deployment.%.%
    elasticsearch_baremetal: 
        isa:  nugget
        impl: templates.deployment.%
    # Basic services configured by a nugget and which need no further implementation
    dovecot_server: 
        isa: nugget
        impl: templates.deployment.%.%

    # Containerized services with customised implementation
    grafana_container: 
        isa: containerized_service
        impl: templates.deployment.%.%
    elasticsearch_container: 
        isa: containerized_service
        impl: templates.deployment.%.%
    nginx_container:
        isa:  containerized_service
        impl: templates.deployment.%.%
    # Containerized services which need no futher implementation
    kibana_container: 
        isa: containerized_service
        impl: super
    logstash_container: 
        isa: containerized_service
        impl: super
    nexus_container: 
        isa: containerized_service
        impl: super
    prometheus_container: 
        isa: containerized_service
        impl: templates.deployment.%.%
