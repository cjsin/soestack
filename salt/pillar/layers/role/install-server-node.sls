{{ salt.loadtracker.load_pillar(sls) }}

# NOTE that in this role, all desired deployments that
# are being modified within this role, should
# be included, even if they are included in other roles.
# This is because the base deployment file (demo.deployments.x)
# needs to be included *before* the values are overridden in this file.

# ie,  the minimum set of includes, is the set of includes
#      for items that are modified within this file.
# and, any other desired deployments for a primary server 
#      node should be included, if they aren't included by
#      another role
include:
    - demo.deployments.types
    - demo.deployments.phpldapadmin
    - demo.deployments.pxeboot
    - demo.deployments.ss-pxe
    - demo.deployments.ss-docs
    - demo.deployments.ss-bundled
    - demo.deployments.pgp-keyserver
    - demo.hosts

