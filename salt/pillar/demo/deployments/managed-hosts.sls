deployments:
    managed_hosts:
        testenv-master:
            host:      infra
            activated:   True
            config:
                domain: demo
                hosts:  managed-hosts:testenv-master
                ipa:    True 
        testenv-client:
            host:      '.*'
            activated:   True
            config:
                domain: demo
                hosts:  managed-hosts:testenv-client
                ipa:    False
