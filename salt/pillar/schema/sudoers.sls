check:
    sudoers: sudoers-config

definitions:
    sudoers-config:
        properties:
            files: $ref:sudoers-files

    sudoers-files:
        propertiesNames: $ref:non-path-string
        otherProperties: $ref:string
