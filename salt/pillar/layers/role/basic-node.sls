{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.types
    - demo.deployments.node-exporter
