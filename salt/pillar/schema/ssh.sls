check:
    ssh: ssh-config
    
definitions:
    ssh-config:
        properties:
            sshd: $ref:sshd-service-config 

    sshd-service-config:
        properties:
            enabled: $boolean
            sshd_config: $ref:sshd-config-file-data

    sshd-config-file-data: $string
