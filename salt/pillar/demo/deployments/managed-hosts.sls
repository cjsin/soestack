_loaded:
    {{sls}}:

deployments:
    managed_hosts:

        testenv-master:
            host:      infra
            activated:   True
            activated_where: {{sls}}
            config:
                domain: demo # NOTE, this domain may be overridden on a different lan
                hosts:  managed-hosts:testenv-master
                ipa:    True 

        testenv-client:
            host:      '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                domain: demo # NOTE, this domain may be overridden on a different lan
                hosts:  managed-hosts:testenv-client
                ipa:    False
