{{ salt.loadtracker.load_pillar(sls) }}

# Defaults for selinux. Note this may be overridden by the security mode (security.<high|low|mid>)

selinux:
    mode: 'permissive'

    booleans:
        # Example of setting booleans (not yet implemented)
        samba_enable_home_dirs: True 
        use_nfs_home_dirs:      True
        samba_share_nfs:        True
        
        # Some possibilities:

        # samba_share_nfs                       # (off)  ,  off)  Allow samba to share nfs
        # samba_enable_home_dirs                # (off)  ,  off)  Allow samba to enable home dirs
        # samba_create_home_dirs                # (off)  ,  off)  Allow samba to create home dirs
        # rsync_full_access                     # (off)  ,  off)  Allow rsync to full access
        # nfs_export_all_ro                     # (on   ,   on)   Allow nfs to export all ro
        # nfs_export_all_rw                     # (on   ,   on)   Allow nfs to export all rw
        # mozilla_plugin_bind_unreserved_ports  # (off)  ,  off)  Allow mozilla to plugin bind unreserved ports
        # mozilla_plugin_use_spice              # (off)  ,  off)  Allow mozilla to plugin use spice
        # httpd_enable_homedirs                 # (off)  ,  off)  Allow httpd to enable homedirs
        # httpd_read_user_content               # (off)  ,  off)  Allow httpd to read user content
        # httpd_can_connect_ldap                # (off)  ,  off)  Allow httpd to can connect ldap
        # git_system_use_nfs                    # (off)  ,  off)  Allow git to system use nfs
        # git_system_enable_homedirs            # (off)  ,  off)  Allow git to system enable homedirs
        # dhcpd_use_ldap                        # (off)  ,  off)  Allow dhcpd to use ldap
        # daemons_use_tcp_wrapper               # (off)  ,  off)  Allow daemons to use tcp wrapper
        # collectd_tcp_network_connect          # (off)  ,  off)  Allow collectd to tcp network connect
        # antivirus_can_scan_system             # (off)  ,  off)  Allow antivirus to can scan system
