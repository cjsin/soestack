_loaded:
    {{sls}}:

include:
    - demo.deployments.nexus-mirror
    - demo.deployments.ipa-master
    - demo.deployments.phpldapadmin
    - demo.deployments.pxeboot
