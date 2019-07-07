{{ salt.loadtracker.load_pillar(sls) }}

# Example data
##############

# managed-hosts:
#     example-deployment-name:
#         infra:
#             ip:       192.168.121.101
#             mac:      '52:54:00:d5:19:d5'
#             aliases:  infra ipa.example ipa salt.example salt ldap.example ldap
#             type:     client
#             hostfile:
#                 - '.*'
