{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.nexus-mirror
    - demo.deployments.ipa-master
    - demo.deployments.phpldapadmin
    - demo.deployments.pxeboot

deployments:
    gitlab_runner_baremetal:
        gitlab-runner:
            hosts:
                - {{grains.host}}
            activated:       True

