check:
    network: network-config 

definitions:
    network-config:
        properties:
            subnet: $ref:subnet-with-prefix
            netmask: $ref:netmask
            prefix: $ref:network-prefix
            gateway: $ref:ip-address
            system_domain: $ref:minimal-domain
            hostfile-additions: $ref:hostfile-additions
            devices: $ref:TODO
            classes: $ref:network-classes
            ipv6: $ref:ipv6-config

    ipv6-config:
        properties:
            mode:
                enum: 
                    - disabled
                    - enabled
                    - lo-only

    network-classes:
        defaults: $ref:network-class
        propertyNames: $pattern:^(defaults|([A-Za-z0-9][-_A-Za-z0-9.]*))
        additionalProperties: $ref:network-class
            
    network-class:
        properties:
            sysconfig:
                propertyNames: $pattern:^[A-Z]+([_A-Z0-9])*$
                additionalProperties: $string

            wpaconfig: $ref:TODO
            ignored: $boolean
            delete: $boolean
        
    recognised-network-sysconfig-key:
        type: string
        enum:
            - BOOTPROTO
            - BROWSER_ONLY
            - DEFROUTE
            - IPV4_FAILURE_FATAL
            - IPV6INIT
            - IPV6_AUTOCONF
            - IPV6_DEFROUTE
            - IPV6_FAILURE_FATAL
            - IPV6_ADDR_GEN_MODE
            - KEY_MGMT
            - NM_CONTROLLED
            - NOZEROCONF
            - ONBOOT
            - PERSISTENT_DHCLIENT
            - PEERDNS
            - PEERROUTES
            - PROXY_METHOD
            - TYPE
            - WPA
            - MODE

    #recognised-network-wpaconfig-key:
    #    type: string
    #    enum: []

    hostfile-additions:
        propertyNames: 
            anyOf:
                - $ref:ip-address
                - $ref:ip6-localhost
        additionalProperties: $ref:hostnames-line
