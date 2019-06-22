include:
    #
    # High priority items
    #

    # Convert role-sets into a roles
    - .role-sets
    # Create configured filesystem areas
    - .filesystem
    # Define package repositories before the states that may need to install packages
    - .repos
    # It can help to install packages before the states that require them
    - .packages
    # Similarly, scripts can be installed prior to use in other states
    - .scripts
    # Set up selinux booleans ASAP before configuring other stuff, to avoid denials
    - .selinux
    
    #
    # Other items - order doesn't matter too much
    #
    - .backups
    - .browser
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
    - .sudoers
    - .services
    - .sysctls
    - .sshd
