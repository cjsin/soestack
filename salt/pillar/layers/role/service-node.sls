_loaded:
    {{sls}}:

include:
    - demo.deployments.gitlab-runner
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.prometheus
    - demo.deployments.simple-http-pxe
    # nginx reverse proxy is not implemented yet
    ## - demo.deployments.nginx-reverse-proxy
