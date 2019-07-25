{{ salt.loadtracker.load_pillar(sls,'host infra') }}

deployments:
    gitlab:
        config:
            # In my demo vm's I have very limited ram available, so need to set this down low
            # The default is that it will use 1/4 of total RAM or so
            postgres_ram: 128MB

network:
    devices:
        eth0:
            inherit:
                - defaults
                - ethernet
                - enabled
                - no-peerdns
                - no-zeroconf
                - no-nm-controlled
                - lan-wired-gateway
                - infra-server
                - infra-dns

postfix:
    mode: server

layer-host-loaded: {{sls}}

