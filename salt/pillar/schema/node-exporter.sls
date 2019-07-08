#check:
#    node_exporter: node-exporter-config

definitions:
    node-exporter-config:
        properties:
            port: $ref:port-number
            storage: $ref:pathname
            options: $array:$string
