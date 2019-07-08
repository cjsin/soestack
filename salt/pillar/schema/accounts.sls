check:
    accounts: accounts-config

definitions:
    accounts-config:
        properties:
            users: $ref:users
            groups: $ref:groups
    users:    
        additionalProperties: $ref:user
    groups:    
        additionalProperties: $ref:group
