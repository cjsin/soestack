_loaded:
    {{sls}}:

deployments:
    managed_hosts:

        testenv-master:
            host:      infra
            activated:   True
            activated_where: {{sls}}
            config:
                domain: demo
                hosts:  managed-hosts:testenv-master
                ipa:    True 

        testenv-client:
            host:      '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                domain: demo
                hosts:  managed-hosts:testenv-client
                ipa:    False
