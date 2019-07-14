{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa_client:
        testenv-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  '!!ipa.server'
                realm:   '!!ipa.realm'
                domain:  '!!ipa.domain'
                site:    default
                ldap:    {}
