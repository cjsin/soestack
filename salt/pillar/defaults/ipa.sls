{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.ipa-client
