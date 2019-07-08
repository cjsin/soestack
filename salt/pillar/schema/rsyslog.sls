
check:
    rsyslog: rsyslog-config

definitions:
    rsyslog-config:
        properties:
            enabled: $boolean
            client: $ref:rsyslog-client
            server: $ref:rsyslog-server

    rsyslog-server:
        properties:
            enabled: $boolean

    rsyslog-client:
        properties:
            enabled: $boolean
            send:
                propertyNames: $ref:ip-address
                additionalProperties: $ref:port-and-protocol
