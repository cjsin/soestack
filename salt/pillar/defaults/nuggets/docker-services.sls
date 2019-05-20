nuggets:
    docker-services:
        description: |
            provides support for services running as docker containers

        install:
            installed:
                package-sets:
                    - docker

        activate:
            service-sets:
                enabled:
                    - docker
