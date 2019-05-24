_loaded:
    {{sls}}:

include:
    - demo.deployments.elasticsearch
    - demo.deployments.gitlab-runner
    - demo.deployments.gitlab
    - demo.deployments.grafana
    - demo.deployments.kibana
    - demo.deployments.logstash-sys
    - demo.deployments.logstash-user
    - demo.deployments.nginx-reverse-proxy
    - demo.deployments.prometheus
    - demo.deployments.simple-http-pxe
