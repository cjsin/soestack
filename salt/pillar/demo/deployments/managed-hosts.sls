{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa-hosts:
        deploy_type: managed_hosts
        roles:
            - ipa-server-node
        activated:   True
        activated_where: {{sls}}
        config:
            domain: demo.com # NOTE, this domain may be overridden on a different lan
            hosts:  managed-hosts:ipa-hosts
            ipa:    True 

    hostfile-hosts:
        deploy_type: managed_hosts

        hosts:
            - '.*'
        activated:   True
        activated_where: {{sls}}
        config:
            domain: demo.com # NOTE, this domain may be overridden on a different lan
            hosts:  managed-hosts:hostfile-hosts
            ipa:    False
