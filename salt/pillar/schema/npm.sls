check:
    npm: npm-config

definitions:

    npm-config:
        properties:
            host_config: $ref:npm-host-config

    npm-host-config:
        properties:
            send-metrics: $boolean
            metrics-registry: $@ref:url
            registry: $@ref:url
