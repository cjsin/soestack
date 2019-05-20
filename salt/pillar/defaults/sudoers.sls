
sudoers:

    files: {}

        #
        # Examples:
        #

        # wheel: |
        #     ## Allows people in group wheel to run all commands
        #     %wheel    ALL=(ALL)       ALL
            
        #     ## Same thing without a password
        #     # %wheel  ALL=(ALL)       NOPASSWD: ALL
        
        # net-restart: |
        #     Cmnd_Alias NETWORK_RESTART = /usr/bin/systemctl restart network
        #     Cmnd_Alias NETWORK_STOP    = /usr/bin/systemctl stop network
        #     Cmnd_Alias NETWORK_START    = /usr/bin/systemctl stop network
        #     ALL ALL=(root) NOPASSWD: NETWORK_RESTART, NETWORK_STOP, NETWORK_START
