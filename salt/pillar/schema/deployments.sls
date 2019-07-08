check:
    deployments: deployments-config

definitions:

    deployments-config:
        propertyNames:        $ref:deployment-type-name
        additionalProperties: $ref:deployment-configs

    deployment-configs:
        propertyNames:        $ref:deployment-name
        additionalProperties: $ref:deployment

    deployment:
        properties:
            filesystem:       $ref:filesystem-config
            config:           $object
