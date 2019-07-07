{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.dovecot-server
    - demo.deployments.gitlab-runner
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.prometheus
    - demo.deployments.simple-http
    # nginx reverse proxy is not implemented yet
    ## - demo.deployments.nginx-reverse-proxy
