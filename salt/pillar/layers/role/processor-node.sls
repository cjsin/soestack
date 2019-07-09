{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.gitlab-runner

runlevel: graphical

network:
    devices:
        eth0:
            inherit:
                - defaults
                - ethernet
                - enabled
                - gateway
                - defroute
                - dhcp
                - no-nm-controlled
                - no-peerdns
                - no-zeroconf

deployments:
    gitlab_runner_baremetal:
        gitlab-runner:
            hosts:
                - {{grains.host}}
            activated:       True
            activated_where: {{sls}}


