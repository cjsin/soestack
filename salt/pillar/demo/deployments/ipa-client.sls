{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa_client:
        demo-ipa-client:
            host:        '.*'
            activated:   True
            activated_where: {{sls}}
            config:
                server:  '!!ipa.server'
                realm:   '!!ipa.realm'
                domain:  '!!ipa.domain'
                site:    default
                ldap:    {}
