lookup:
    ipv6:
        sysctls:
            enabled: |
                net.ipv6.conf.all.disable_ipv6 = 0
                net.ipv6.conf.default.disable_ipv6 = 0
                net.ipv6.conf.lo.disable_ipv6 = 0
            disabled: |
                net.ipv6.conf.all.disable_ipv6 = 1
                net.ipv6.conf.default.disable_ipv6 = 1
                net.ipv6.conf.lo.disable_ipv6 = 1
            default: |
                # This file deliberately empty - use OS defaults
            lo-only: |
                net.ipv6.conf.all.disable_ipv6 = 1
                net.ipv6.conf.default.disable_ipv6 = 1
                net.ipv6.conf.lo.disable_ipv6 = 0
