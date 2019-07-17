{{ salt.loadtracker.load_pillar(sls) }}

include:

    - defaults.nuggets.firewall-implementations
    - defaults.nuggets.iptables-firewall
    - defaults.nuggets.dhcp-server
    - defaults.nuggets.dhcp-server-dnsmasq
    - defaults.nuggets.tftp-server-xinetd
    #- defaults.nuggets.test-nugget
    - defaults.nuggets.ipa
    - defaults.nuggets.pxeboot-server
    - defaults.nuggets.nfs-server
    - defaults.nuggets.managed-hosts
    - defaults.nuggets.dnsmasq
    - defaults.nuggets.dovecot-server
    - defaults.nuggets.pgp-keyserver
