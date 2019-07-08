check:
    dns: dns-config

definitions:
    dns-config:
        properties:
            server: $ref:fqdn
            nameservers: $ref:dns-server-map
            search: $ref:search-domain-map
    dns-server-map:
        propertyNames: $pattern:^dns[123]$
        additionalProperties:
            anyOf:
                - $ref:missing-value
                - $ref:ip-address
    search-domain-map:
        propertyNames: $pattern:^search[1-9]$
        additionalProperties:
            anyOf:
                - $ref:missing-value
                - $ref:any-domain
