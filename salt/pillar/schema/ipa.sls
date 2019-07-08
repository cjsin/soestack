check:
    ipa: ipa-config
    ipa-configuration: ipa-postinstall-config

example-data:
    ipa:
        # NOTE: IPA uses the REALM to generate the base dn, dc=xxx, not the dns domain
        server:    infra.demo.com
        server_ip: '!!demo.ips.infra'
        base_dn:   dc=demo,dc=com
        bind_user: bind-user
        realm:     DEMO.COM

definitions:
    ipa-config:
        properties:
            server:     $ref:fqdn
            server_ip:  $ref:ip-address
            base_dn:    $ref:ipa-dc
            bind_user:  $ref:non-empty-string
            realm:      $ref:ipa-realm
            domain:     $ref:minimal-domain

    ipa-postinstall-config:
        properties:
            automounts: $ref:ipa-automount-config

    ipa-automount-config:
        properties:
            maps:
                propertyNames: $pattern:^auto[.]([a-z]+)$
                additionalProperties: $ref:ipa-automount-maps

    ipa-automount-maps:
        properties:
            type: $pattern:^(direct)$
            keys: $ref:ipa-automount-keys 

    ipa-automount-keys:
        propertyNames:
            anyOf:
                - $pattern:^[*]$
                - $ref:non-empty-path
            additionalProperties: $string
