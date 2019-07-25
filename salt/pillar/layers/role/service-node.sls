{{ salt.loadtracker.load_pillar(sls) }}

# Deployments for any *services* that can run on any server.
# (not any systemd services, but for example any systemd service which
# is providing a service to the network)
# also this generally excludes primary-server-node services
# such as IPA
include:
    - demo.deployments.types
    - demo.deployments.dovecot-server
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.prometheus
    - demo.deployments.simple-http
    # nginx reverse proxy is not implemented yet
    ## - demo.deployments.nginx-reverse-proxy
    - demo.deployments.nexus-mirror
    - demo.deployments.phpldapadmin
    - demo.deployments.gitlab-runner
    - demo.deployments.dovecot-server
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.prometheus
    - demo.deployments.simple-http
    - demo.hosts
