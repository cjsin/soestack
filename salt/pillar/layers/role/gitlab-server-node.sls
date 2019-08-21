{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.types
    - demo.deployments.gitlab-runner
    - demo.deployments.gitlab
