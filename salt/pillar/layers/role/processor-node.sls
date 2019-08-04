{{ salt.loadtracker.load_pillar(sls) }}

include:
    - demo.deployments.types
    - demo.deployments.gitlab-runner
    - demo.deployments.logstash-sys
    - demo.deployments.logstash-user
    - demo.deployments.node-exporter

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
    ss-runners:
        hosts:
            - {{grains.host}}
        activated:       True
        activated_where: {{sls}}


