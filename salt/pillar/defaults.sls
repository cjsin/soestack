{{ salt.loadtracker.load_pillar(sls) }}

_layers_test:
    defaults:     {{sls}}
    defaults-value:  'defaults'
    test_value:  'defaults'
    additive:
        - defaults

layers_test:
    defaults:     {{sls}}
    defaults-value:  'defaults'
    test_value:  'defaults'
    additive:
        - defaults

include:
    # Load nuggets first
    - defaults.nuggets 
    - defaults.nuggets-enabled
    - defaults.activated-states
    - defaults.accounts
    - defaults.backups
    - defaults.bash
    - defaults.branding
    - defaults.build-defaults
    - defaults.build-packages
    - defaults.cups
    - defaults.docker
    - defaults.firewall
    - defaults.gitlab
    - defaults.example-gpgdata
    - defaults.grafana
    - defaults.ipa
    - defaults.ipv6
    - defaults.lan
    - defaults.less
    - defaults.lookup
    - defaults.nexus
    - defaults.node_exporter
    - defaults.npm
    - defaults.package-groups-roles
    - defaults.package-groups
    - defaults.package-selection
    - defaults.package-sets
    - defaults.pip
    - defaults.prometheus
    - defaults.roles
    - defaults.role-sets
    - defaults.rsyslog
    - defaults.rubygems
    - defaults.runlevel
    - defaults.selinux
    - defaults.service-reg
    - defaults.service-sets
    - defaults.services
    - defaults.sudoers
    - defaults.versions
    - defaults.timezone
    - defaults.thunderbird
