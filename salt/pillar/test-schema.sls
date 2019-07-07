{{ salt.loadtracker.load_pillar(sls) }}

pillar-schema:
    schema:
        $schema: 'http://json-schema.org/draft-07/schema#'
        definitions:
            basic-data:
                type: object
                properties:
                    a-number:
                        type: integer
                    a-string:
                        type: string
                    a-list:
                        type: array
                        items:
                            type: string
                    a-mapping:
                        $ref: '#/definitions/int-mapping'
            int-mapping:
                type: object
                additionalProperties:
                    type: integer
            complex-data:
                type: object
                properties:
                    deployment:
                        $ref: '#/definitions/deployment'
                required:
                    - deployment
            deployment:
                type: object
                properties:
                    filesystem:
                        $ref: '#/definitions/filesystem'
                    config: 
                        type: object
            
                required:
                    - config
                    - filesystem

            filesystem:
                type: object
                properties:
                    files: 
                        $ref: '#/definitions/files'
                    dirs: 
                        $ref: '#/definitions/dirs'
        
            files:
                type: object
        
            dirs:
                type: object

            test-schema:
                title: test-schema
                description: data for testing the schema validation
                type: object
                properties:
                    basic-data:
                        $ref: '#/definitions/basic-data'
                    complex-data: 
                        $ref: '#/definitions/complex-data'
                required:
                    - basic-data
                    - complex-data

    check:
        good-data: test-schema
        bad-data:  test-schema
