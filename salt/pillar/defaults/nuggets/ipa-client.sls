nuggets:
    ipa-client:
        description: |
            provides support for enrolling a node with an IPA server

        install:
            nuggets-required:
                - managed-hosts
                
            installed:
                package-sets:
                    - ipa-client

        activate:
            firewall:
                firewall-rule-sets:
                    - ipa-client
