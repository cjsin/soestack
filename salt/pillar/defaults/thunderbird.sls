{{ salt.loadtracker.load_pillar(sls) }}

thunderbird:
    autoconfig:
        demo.com:
            server: infra.demo.com
            domain: demo.com
