{{ salt.loadtracker.load_pillar(sls) }}

pillar-schema:
    check:
        dns: dns-config

    example-data:
        ipa:
            # NOTE: IPA uses the REALM to generate the base dn, dc=xxx, not the dns domain
            server:    infra.demo.com
            server_ip: '!!demo.ips.infra'
            base_dn:   dc=demo,dc=com
            bind_user: bind-user
            realm:     DEMO.COM

    schema:
        $schema: 'http://json-schema.org/draft-07/schema#'
        definitions:
            network-config:
                properties:
                    subnet:
                        $ref: '#/definitions/subnet-with-prefix'
                    netmask:
                        $ref: '#/definitions/netmask'
                    prefix:
                        $ref: '#/definitions/network-prefix'
                    gateway: 
                        $ref: '#/definitions/ip-address'
                    system_domain:
                        $ref: '#/definitions/minimal-domain'
                    hostfile-additions:
                        $ref: '#/definitions/hostfile-additions'
                    classes:
                        # TODO
                        type: object
            hostfile-additions:
                type: object
                propertyNames:
                    $ref: '#/definitions/ip-address'
                additionalProperties:
                    $ref: '#/definitions/hostnames-line'
            hostnames-line:
                type: string
                pattern: ^[[:space:]]*(([a-zA-Z][a-zA-Z0-9]+)([.][a-zA-Z][a-zA-Z0-9]+)*)([[:space:]]+(([a-zA-Z][a-zA-Z0-9]+)([.][a-zA-Z][a-zA-Z0-9]+)*))[[:space:]]*$
            dns-config:
                properties:
                    server:
                        $ref: '#/definitions/fqdn'
                    nameservers:
                        $ref: '#/definitions/dns-server-map'
                    search:
                        $ref: '#/definitions/search-domain-map'
            search-domain-list:
                type: array
                children:
                    $ref: '#/definitions/any-domain'
            dns-server-map:
                propertyNames:
                    pattern: '^dns[123]$'
                additionalProperties:
                    anyOf:
                        - $ref: '#/definitions/missing-value'
                        - $ref: '#/definitions/ip-address'
            search-domain-map:
                propertyNames:
                    pattern: '^search[1-9]$'
                additionalProperties:
                    anyOf:
                        - $ref: '#/definitions/missing-value'
                        - $ref: '#/definitions/any-domain'
            null-value:
                type: "null"
            missing-value:
                anyOf:
                    - $ref: '#/definitions/null-value'
                    - $ref: '#/definitions/empty-string'
            full-subnet-without-prefix:
                type: string 
                pattern: '^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}$'
            full-subnet-with-prefix:
                type: string 
                pattern: '^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}/([0-9]|[12][0-9]|3[012])$'
            subnet-with-prefix:
                type: string 
                pattern: '^([012][0-9]{0,2})([.][012][0-9]{0,2}){0,3}/([0-9]|[12][0-9]|3[012])$'
            subnet-without-prefix:
                type: string 
                pattern: '^([012][0-9]{0,2})([.][012][0-9]{0,2}){0,3}$'
            ip-address:
                type: string
                pattern: '^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}$'
            ip-address-list:
                type: array
                children:
                    $ref: '#/definitions/ip-address'
            network-prefix:
                type: integer
                minimum: 1
                maximum: 32
            non-empty-string:
                type: string
                minLength: 1
            empty-string:
                type: string
                maxLength: 0
            accounts:
                properties:
                    users:
                        $ref: '#/definitions/users'
                    groups:
                        $ref: '#/definitions/groups'
            users:    
                additionalProperties: 
                    $ref: '#/definitions/user'
            groups:    
                additionalProperties: 
                    $ref: '#/definitions/group'
            user:    
                properties:
                    uid:
                        type: integer
                    fullname: 
                        $ref: '#/definitions/non-empty-string'
                    home:
                        $ref: '#/definitions/absolute-path'
                    shell:
                        $ref: '#/definitions/absolute-path'
                    groups:
                        type: array
                        children:
                            $ref: '#/definitions/non-empty-string'
            group:    
                properties:
                    gid:
                        type: integer
            ipa-config:
                properties:
                    server:    
                        $ref:  '#/definitions/fqdn'
                    server_ip: 
                        $ref:  '#/definitions/ip-address'
                    base_dn:   
                        $ref:  '#/definitions/ipa-dc'
                    bind_user: 
                        $ref:  '#/definitions/non-empty-string'
                    realm:     
                        $ref:  '#/definitions/ipa-realm'
                    domain:    
                        $ref:  '#/definitions/minimal-domain'
            ipa-dc:
                type: string 
                pattern: '^(dc=[a-z][a-z0-9]*)(,dc=[a-z][a-z0-9]*)*$'
            ipa-realm:
                type: string
                pattern: '^([A-Z][A-Z0-9]*)([.][A-Z][A-Z0-9]*)*$'
            hostname:
                type: string
                pattern: '^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*)*$'
            short-hostname:
                type: string
                pattern: '^([A-Za-z][A-Za-z0-9]*)$'
            fqdn:
                type: string
                pattern: '^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*){2,}$'
            minimal-domain:
                type: string
                pattern: '^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*)+$'
            any-domain:
                type: string
                pattern: '^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*)*$'
            int-mapping:
                type: object
                additionalProperties:
                    type: integer
            deployment:
                type: object
                properties:
                    filesystem:
                        $ref: '#/definitions/filesystem'
                    config: 
                        type: object
            
                required:
                    - config
                    - filesystem
            filesystem:
                type: object
                properties:
                    files: 
                        $ref: '#/definitions/files'
                    dirs: 
                        $ref: '#/definitions/dirs'
            files:
                type: object
        
            dirs:
                type: object

