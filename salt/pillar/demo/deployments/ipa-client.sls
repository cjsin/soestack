deployments:
    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            config:
                server:  infra.demo
                realm:   DEMO
                domain:  demo
                site:    demo
                ldap:
                    base-dn: dc=demo
