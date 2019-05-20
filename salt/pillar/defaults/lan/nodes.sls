

# No nodes are defined by default.
# 
# To support automatic IPA node enrollment or PXE boot installs, 
#   define some nodes in your lan,site,or soe layer
# Or, if you have an sls file for every host, then this data could
#   be set there individually for each host.

nodes:

    # Example of specifying node mac-address/IP for PXE boot support
    # infra:
    #     mac:  01:02:03:04:05:06
    #     ip:   192.168.121.101

