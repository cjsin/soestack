definitions:
    TODO: $object

    ipa-dc: $pattern:^(dc=[a-z][a-z0-9]*)(,dc=[a-z][a-z0-9]*)*$
    ipa-realm: $pattern:^([A-Z][A-Z0-9]*)([.][A-Z][A-Z0-9]*)*$

    null-value:
        type: "null"
    missing-value:
        anyOf:
            - $ref:null-value
            - $ref:empty-string
    full-subnet-without-prefix: $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}$
    full-subnet-with-prefix: $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}/([0-9]|[12][0-9]|3[012])$
    subnet-with-prefix: $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){0,3}/([0-9]|[12][0-9]|3[012])$
    subnet-without-prefix: $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){0,3}$
    ip-address: $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}$
    netmask:    $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}$
    ip-address-list: $array:$ref:ip-address
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
    any-string: $string

    any-string-or-null:
        anyOf:
            - $ref:any-string
            - $ref:null-value

    path:
        type: string
        anyOf:
            - $pattern:^/.*$
            - $pattern:^[^/].*$

    non-path-string: $pattern:^(|[^/]+)$
    nonempty-non-path-string: $pattern:^[^/]+$

    bool-or-binary-onoff:
        anyOf:
            - $boolean
            - $ref:binary-onoff

    binary-onoff:
        anyOf:
            - $ref:zero-or-one
            - $ref:zero-or-one-string

    zero-or-one:
        type: integer
        minimum: 0
        maximum: 1

    zero-or-one-string: $pattern:^[01]$

    port-and-protocol:
        properties:
            port: $ref:port-number
        protocol: $ref:alphanumeric-string

    alphanumeric-string: $pattern:^([a-z][A-Za-z0-9]+)$

    hostname-with-optional-port: $pattern:^[a-zA-Z][a-zA-Z0-9]*([.][a-zA-Z][a-zA-Z0-9])*(|:[0-9]+)$

    ip-address-with-optional-port: $pattern:^([012][0-9]{0,2})([.][012][0-9]{0,2}){3}(|:[0-9]+)$

    hostname-or-ip-address-with-optional-port:
        anyOf:
            - $ref:hostname-with-optional-port
            - $ref:ip-address-with-optional-port

    hostname-or-ip-address:
        anyOf:
            - $ref:hostname
            - $ref:ip-address

    timezone:
        type: string 
        anyOf:
            - $ref:timezone-number
            - $ref:timezone-name

    timezone-number: $pattern:^(?:Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])$

    timezone-name: $pattern:^([A-Za-z0-9][-+_A-Za-z0-9]*(|/[A-Za-z0-9][-+_A-Za-z0-9]*))$

    rpm-name-prefix: $pattern:^[A-Za-z0-9][-_A-Za-z0-9]*$

    username-or-email:
        type: string
        anyOf:
            - $ref:username
            - $ref:simple-email-address

    simple-email-address: $pattern:^[A-Za-z0-9][A-Za-z0-9_-.]*@[A-Za-z0-9][A-Za-z0-9-]*([.][A-Za-z0-9][A-Za-z0-9-]*)*$


    role-name-csv: $pattern:^([a-zA-Z][-a-zA-Z0-9]*)*(,([a-zA-Z][-a-zA-Z0-9])*)*$

    service-name: $ref:non-path-string

    hostname: $pattern:^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*)*$
    short-hostname: $pattern:^([A-Za-z][A-Za-z0-9]*)$
    fqdn: $pattern:^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*){2,}$
    minimal-domain: $pattern:^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*)+$
    any-domain: $pattern:^([A-Za-z][A-Za-z0-9]*)([.][A-Za-z][A-Za-z0-9]*)*$
    int-mapping:
        additionalProperties: $integer

    hostnames-line: $pattern:^[ \t]*(([a-zA-Z][-a-zA-Z0-9]*)([.][a-zA-Z][-a-zA-Z0-9]*)*)([ \t]+(([a-zA-Z][-a-zA-Z0-9]*)([.][a-zA-Z][a-zA-Z0-9]*)*))*[ \t]*$
    search-domain-list: $array:$ref:any-domain

    user:    
        properties:
            uid: $integer
            fullname: $ref:non-empty-string
            home: $ref:absolute-path
            shell: $ref:absolute-path
            groups: $array:$ref:non-empty-string
    group:    
        properties:
            gid: $integer

    absolute-path: $pattern:^/.*$


    deployment-name:      $ref:basic-string #$ref:dashed-basic-string
    deployment-type-name: $ref:basic-string #$ref:underscores-basic-string
    basic-string:         $pattern:^([A-Za-z0-9][-_A-Za-z0-9]*)$
    dashed-basic-string:  $pattern:^([A-Za-z0-9][-A-Za-z0-9]*)$
    underscores-basic-string:  $pattern:^([A-Za-z0-9][_A-Za-z0-9]*)$
    username: $ref:basic-string
    groupname: $ref:basic-string
    filesystem-mode: $pattern:^[0-9]{3,4}$
    port-number:
        type: integer
        minimum: 0
        maximum: 65535

    username-or-uid:
        anyOf:
            - $integer
            - $ref:username

    groupname-or-gid:
        anyOf:
            - $integer
            - $ref:groupname

    url: $pattern:^([a-z]+)://([A-Za-z][-A-Za-z0-9]*)([.][A-Za-z][-A-Za-z0-9]*)*(|:[0-9]{1,5})($|/.*$)
    flexible-url:
        anyOf:
            - $ref:url
            - $ref:hostname-or-ip-address-with-optional-port

    ip6-localhost: $pattern:^::1$
