check:
    soe: soe-config

definitions:
    soe-config:
        properties:
            name:        $ref:non-empty-string
            description: $ref:non-empty-string
        requiredProperties:
            - name
            - description
