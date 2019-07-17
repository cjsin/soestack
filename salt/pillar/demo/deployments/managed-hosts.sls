{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    managed_hosts:

        demo-ipa-master:
            host:      infra
            activated:   True
            activated_where: {{sls}}
            config:
                domain: demo # NOTE, this domain may be overridden on a different lan
                hosts:  managed-hosts:demo-ipa-master
                ipa:    True 

        demo-ipa-client:
            host:      '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                domain: demo # NOTE, this domain may be overridden on a different lan
                hosts:  managed-hosts:demo-ipa-client
                ipa:    False
