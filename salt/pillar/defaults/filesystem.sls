
filesystem:

    defaults:
        user:  root
        group: root
        mode:  '0644'

    dirs:
    
        defaults:
            mode:  '0755'
            export: False
            bind:  ''

        #common:
        #    /d:
        #        description: Data storage area
        #
        #    /d/local:
        #        description: Data storage area for local data
        #
        #    /var/log/everything: 
        #        mode: '0750'
        #        description: Logs split by day
        #
        #by-role:
        #    primary-server:
        #        /export:
        #            description: Top directory for nfs exports
        #
        #        /var/log/clients: 
        #            mode: '0750'
        #            description: Client logs split by day
        #
        #        /home:
        #            description: Home directories for users
        #            bind:   /export/home
        #            export: /export/home

    # symlinks not yet implemented
    # symlinks:
