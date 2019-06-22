_loaded:
    {{sls}}:

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

