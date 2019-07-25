{{ salt.loadtracker.load_pillar(sls) }}

deployment-sequence:
    - managed_hosts

    # NOTE the order of these is important, because for example
    # IPA will fail to install if Gitlab is running and using port 80,
    # even bound with a different IP - since IPA attempts to bind using 0.0.0.0 (with httpd)
    # at instalation time.

    # nexus container is first deployed by the infra server setup script
    # but is updated by this deployment
    - nexus_container

    # dovecot is deployed before ipa master so that /etc/skel has a Maildir prior
    # to preconfigured user account homedir creation
    - dovecot_server

    - ipa
    - simple_http
    - pxeboot_server
    - node_exporter_baremetal
    - prometheus_container
    - grafana_baremetal
    - grafana_container
    - nginx_container
    - gitlab_baremetal
    - elasticsearch_container
    - kibana_container
    - kibana_baremetal
    - logstash_container
    - logstash_baremetal
    - kube_master
