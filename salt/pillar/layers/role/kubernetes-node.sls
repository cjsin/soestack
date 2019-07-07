{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.kube-master
