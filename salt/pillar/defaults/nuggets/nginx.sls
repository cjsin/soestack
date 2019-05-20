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
        