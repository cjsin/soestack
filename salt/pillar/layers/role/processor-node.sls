{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.types
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
    ss-gitlab-runners:
        hosts:
            - {{grains.host}}
        activated:       True
        activated_where: {{sls}}


