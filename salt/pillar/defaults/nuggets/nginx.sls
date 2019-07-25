{{ salt.loadtracker.load_pillar(sls) }}

nuggets:

    nginx:
        description: |
            provides support for deploying nginx but does not deploy any
            particular instance

        install:
            # This nugget does not configure a service
            # because it's likely that multiple different deployments will be
            # be created
            installed:
                package-sets:
                    - nginx
        activate: {}



    nginx-container:

        filesystem:
            defaults:
                user:      root
                group:     root
                dir_mode:  '0755'
                file_mode: '0644'
            dirs:
                /etc/nginx:
