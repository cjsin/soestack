check:
    nexus-repos: selected-nexus-repos
    nexus: nexus-config 

definitions:

    nexus-config:
        properties:
            http_address: $ref:hostname-or-ip-address-with-optional-port
            docker_address: $ref:hostname-or-ip-address-with-optional-port
            urls:
                additionalProperties: $@ref:flexible-url
            blobstores:
                propertyNames: $ref:basic-string
                additionalProperties: $ref:null-value
            repos:
                propertyNames: $ref:basic-string
                additionalProperties: $ref:nexus-repository-definition

    nexus-repository-definition:
        properties:
            type: $ref:nexus-repository-type
            format: $ref:nexus-repository-format
            blobstore: $ref:basic-string
            repodata_depth: $integer
            deploy_policy: $ref:nexus-deploy-policy
            remote_url:  $ref:flexible-url
            yum:  $ref:nexus-yum-repository-config
            docker: $ref:nexus-docker-repository-config


    nexus-repository-type: $enum:hosted,proxy

    nexus-deploy-policy: $pattern:^(Permissive)$

    nexus-repository-format: $enum:yum,pypi,npm,rubygems,raw,docker


    nexus-yum-repository-config:
        properties:
            description: $ref:non-empty-string
            path:  $ref:path-string
            enabled: $ref:bool-or-binary-onoff
            gpgcheck: $ref:bool-or-binary-onoff
            gpgkey: $string
            gpgkey_url: $ref:url
            additionalProperties: $ref:nexus-yum-os-repos

    nexus-yum-os-repos:
        properties:
            repos: $ref:os-repo-defs

    os-repo-defs:
        propertyNames: $ref:os-name-list
        additionalProperties: $ref:nexus-yum-repo-definition

    os-name-list: $pattern:^([A-Za-z0-9][-A-Za-z0-9]*)(,[A-Za-z0-9][-A-Za-z0-9]*)*$

    
    nexus-docker-repository-config:
        properties:
            http_connector: $ref:port-number
            docker_index: 
                type: string
                enum: 
                    - Use proxy registry
                    - Use Docker Hub
            enable_v1_api: $boolean
            force_basic_authentication: $pattern:^(un|)checked$


    selected-nexus-repos:
        defaults: $ref:nexus-repo-enabling-set
        additionalProperties: $ref:nexus-os-specific-repo-enabling-set

    nexus-os-specific-repo-enabling-set:
        propertyNames: $ref:os-name-list
        additionalProperties: $ref:nexus-repo-enabling-set

    nexus-repo-enabling-set:
        propertyNames: $ref:basic-string
        aditionalProperties:
            anyOf:
                - $boolean
                - properties:
                    enabled: $boolean
