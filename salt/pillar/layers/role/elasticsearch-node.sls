{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.elasticsearch
    - demo.deployments.kibana
    - demo.deployments.logstash-sys
    - demo.deployments.logstash-user
