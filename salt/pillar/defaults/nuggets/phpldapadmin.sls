{{ salt.loadtracker.load_pillar(sls) }}

nuggets:

    phpldapadmin-baremetal:
        description: |
            provides support for deploying phpldapadmin but does not deploy any
            particular instance

        install:
            # This nugget does not configure a service
            # because it's likely that multiple different deployments will be
            # be created
            installed:
                package-sets:
                    - phpldapadmin
        activate: {}

