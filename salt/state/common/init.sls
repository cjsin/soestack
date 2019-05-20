include:
    #
    # High priority items
    #

    # Convert role-sets into a roles
    - .role-sets.apply
    # Create configured filesystem areas
    - .filesystem
    # Define package repositories before the states that may need to install packages
    - .repos
    # It can help to install packages before the states that require them
    - .packages

    #
    # Other items - order doesn't matter too much
    #
    - .backups
    - .bash
    - .dns
    - .docker
    - .email
    - .hosts
    - .ipv6
    - .mail
    - .node_exporter
    - .npm
    - .pip
    - .printing
    - .readline
    - .rsyslog
    - .rubygems
    - .runlevel
    - .salt
    - .selinux
    - .sudoers
    - .services
    - .sysctls
    - .sshd
