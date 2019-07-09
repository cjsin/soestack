{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  infra.default
                realm:   DEFAULT
                domain:  default
                site:    default
                ldap:    {}
