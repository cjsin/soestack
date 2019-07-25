{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.types
    ## - demo.deployments.nginx-reverse-proxy
    - demo.deployments.phpldapadmin
