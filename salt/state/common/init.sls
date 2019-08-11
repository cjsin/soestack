include:
    #
    # High priority items
    #

    # Convert role-sets into a roles
    - .role-sets
    # Set up ssh access for root as soon as possible
    - .sshd
    # Set up dns ASAP as lack of dns resolution can break access to repos
    - .dns
    # Create configured filesystem areas
    - .filesystem
    - .firewall
    # Define package repositories before the states that may need to install packages
    - .repos
    # Similarly, scripts can be installed prior to use in other states
    - .scripts
    # It can help to install packages before the states that require them
    - .packages
    # Set up selinux booleans ASAP before configuring other stuff, to avoid denials
    - .selinux
    
    #
    # Other items - order doesn't matter too much
    #
    - .antivirus
    - .backups
    - .branding
    - .browser
    #- .banners
    - .bash
    #- .desktop
    - .docker
    - .email
    - .hosts
    - .ipv6
    - .mail
    - .npm
    - .pip
    - .printing
    - .readline
    - .rsyslog
    - .rubygems
    - .runlevel
    - .salt
    #- .screensaver
    - .sudoers
    - .services
    - .sysctls
    - .terminator
    - .runlevel
