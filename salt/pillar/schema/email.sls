check:
    email: email-config

definitions:
    email-config:
        properties:
            aliases: $ref:email-aliases

    email-aliases:
        propertyNames: $ref:username-or-email 
        additionalProperties: $ref:username-or-email 
