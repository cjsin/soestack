check:
    filesystem: filesystem-config

definitions:
    filesystem-config:
        properties:
            dirs: $ref:filesystem-dirs-config-groups
            files: $ref:filesystem-files-config-groups
            symlinks: $ref:filesystem-symlinks-config-groups

    filesystem-files-config-groups:
        properties:
            common: $ref:filesystem-files-config
            by-role:
                propertyNames: $ref:role-name-csv
                additionalProperties: $ref:filesystem-files-config

    filesystem-symlinks-config-groups:
        properties:
            common: $ref:filesystem-symlinks-config
            by-role:
                propertyNames: $ref:role-name-csv
                additionalProperties: $ref:filesystem-symlinks-config

    filesystem-dirs-config-groups:
        properties:
            common: $ref:filesystem-dirs-config
            by-role:
                propertyNames: $ref:role-name-csv
                additionalProperties: $ref:filesystem-dirs-config

    filesystem-dirs-config:
        propertyNames: $ref:path 
        additionalProperties: $ref:filesystem-dir-config
    
    filesystem-files-config:
        propertyNames: $ref:path 
        additionalProperties: $ref:filesystem-files-config
    
    filesystem-symlinks-config:
        propertyNames: $ref:path 
        additionalProperties: $ref:filesystem-symlinks-config
            
    filesystem-dir-config:
        properties:
            description: $string
            mode: $ref:filesystem-mode
            user: $ref:username-or-uid
            group: $ref:groupname-or-gid
            mkdirs: $boolean
            export: $ref:directory-exports-config
            bind: $ref:bind-dirs-config
                    # export:
                    #     0-toplevel:
                    #         '*':              ro,async,root_squash,insecure,fsid=0

    filesystem-symlink-config:
        properties:
            description: $string
            mode: $ref:filesystem-mode
            user: $ref:username-or-uid
            group: $ref:groupname-or-gid
            mkdirs: $boolean
            target: $ref:path

    filesystem-file-config:
        properties:
            description: $string
            mode: $ref:filesystem-mode
            user: $ref:username-or-uid
            group: $ref:groupname-or-gid
            mkdirs: $boolean
    
    directory-exports-config: 
        propertyNames: $ref:basic-string
        additionalProperties: $ref:directory-exports-config-items
        #additionalProperties: 
    
    #directory-exports-config-items: $array:$ref:path-to-string-mapping
    directory-exports-config-items: 
        propertyName: $ref:basic-string
        additonalProperties: $string

    path-to-string-mapping:
        propertyNames: $ref:absolute-path
        additonalProperties: $string

    bind-dirs-config:
        properties:
            dev:       $ref:path
            readwrite: $boolean
