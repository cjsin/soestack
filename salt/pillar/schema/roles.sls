check:
    roles: roles-config 

definitions:
    roles-config:
        propertyNames: $ref:role-name
        properties:
            purpose: $string

    role-name: $pattern:^([A-Za-z0-9][-_A-Za-z0-9]*)$
