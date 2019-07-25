{{ salt.loadtracker.load_pillar(sls) }}

_layers_test:
    role:       {{sls}}
    role_value: 'role-infra-server-node'
    test_value: 'role-infra-server-node'
    additive:
        - role-infra-server-node

layers_test:
    role:       {{sls}}
    role_value: 'role-infra-server-node'
    test_value: 'role-infra-server-node'
    additive:
        - role-infra-server-node

# NOTE that in this role, all desired deployments that
# are being modified within this role, should
# be included, even if they are included in other roles.
# This is because the base deployment file (demo.deployments.x)
# needs to be included *before* the values are overridden in this file.

# ie,  the minimum set of includes, is the set of includes
#      for items that are modified within this file.
# and, any other desired deployments for a primary server 
#      node should be included, if they aren't included by
#      another role

include:
    - demo.deployments.types
    - demo.deployments.ipa
    - demo.deployments.managed-hosts
    - demo.deployments.node-exporter
    - demo.deployments.nexus-mirror
    - demo.deployments.phpldapadmin
    - demo.deployments.pxeboot
    - demo.deployments.gitlab-runner
    - demo.deployments.dovecot-server
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.prometheus
    - demo.deployments.pgp-keyserver
    - demo.deployments.ss-docs
    - demo.deployments.ss-pxe
    - demo.deployments.ss-epel
    - demo.hosts

deployments:
    gitlab-runner:
        hosts:
            - {{grains.host}}
        activated:       True
        activated_where: {{sls}}

