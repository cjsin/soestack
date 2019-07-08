check:
    service-status: service-status-config 
    service-reg: service-reg-config 

definitions:
    service-status-config:
        properties:
            service-sets:
                properties:
                    enabled: $array:$ref:service-name
                    disabled: $array:$ref:service-name
            services:
                properties:
                    enabled:  $array:$ref:service-name
                    disabled: $array:$ref:service-name

    service-reg-config:
        propertyNames: $ref:non-empty-string
        otherProperties: $ref:hostname-or-ip-address-with-optional-port


    # service-reg:
    #     propertiesNames: $ref:non-path-string
    #     otherProperties: $ref:hostname-with-optional-port

