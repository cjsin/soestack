check:
    node_lists: node-list-node
    
definitions:
    node-list-node:
        propertyNames: $ref:non-empty-string
        additionalProperties:
            anyOf:
                - $ref:node-list-leaf
                - $ref:node-list-node

    node-list-leaf: $array:$ref:hostname-or-ip-address
