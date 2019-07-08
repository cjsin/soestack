check:
    installed_scripts: script-installation-sets

definitions:

    script-installation-sets:
        propertyNames: $ref:basic-string
        properties:
            from: $ref:url
            to: $ref:path 
            mode: $ref:filesystem-mode
            common: $ref:script-name-list
            additionalProperties:
                propertyNames:
                    $ref:os-name-list
                additionalProperties:
                    $ref:script-name-list

    script-name-list: $array:$ref:script-name

    script-name: $ref:non-path-string

