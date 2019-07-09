{{ salt.loadtracker.load_pillar(sls) }}

docker:
    config:
        daemon:
            insecure-registries: 
                # Example insecure registry specification
                # - nexus:7082
