deployments:
    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            config:
                server:  infra.default
                realm:   DEFAULT
                domain:  default
                site:    default
                ldap:    {}
