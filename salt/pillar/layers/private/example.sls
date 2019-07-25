{{ salt.loadtracker.load_pillar(sls) }}

# This is an example 'private.sls' file - to use it,
# put it in a subdirectory, renamed to private.sls,
# and then set ss.LAYERS (or the 'layers' grain) to
# specify that directory name for the 'private' layer.
# 
# For example:
#     - create subdir 'example'
#     - rename this file ('example.sls') to example/private.sls
#     - add your other private sls files within the example subdir
#     - edit example/private.sls to 'include' your other private sls files
#       NOTE that because of the jinja include, the 'include' will need to
#       use full paths, eg layers.private.<layername>.<xxx>
#
#  then, when provisioning:
#     add 'private:example' to ss.LAYERS provisioning variable
#        (for example ss.LAYERS=soe:demo,site:testing,lan:home,private:example.private )
#
#   or if already provisioned and just updating the salt configuration:
#     set the salt layers grain: to include 'private: example'
#        (for example salt-call grains.set layers:private example.private 

# This file can be used to include others which are not
# checked into a git repo

# The .gitignore file is set to ignore everthing except itself
# and this example file

# Example contents after renaming to 'salt/pillar/layers/private/example/private.sls'
#include:
#    - layers.private.example.secrets
#    - layers.private.example.timezone

# OR you might just want to include the private stuff there directly, for example:

# timezone: Some/Timezone

# ssh:
#     authorized_keys:
#         root:
#             root@infra.demo.com: a-big-long-root-ssh-key
# deployments:
#     gitlab_runner_baremetal:
#         gitlab-runner:
#             config:
#                 registration_token: example-gitlab-runner-token
#     gitlab_baremetal:
#         gitlab:
#             config:
#                 mattermost:
#                     app_id:       a-gitlab-application-app-id
#                     token:        a-gitlab-application-secret-token

# network:
#     classes:
#         home-test-environment:
#             wpaconfig:
#                 home-test-environment: |
#                     network={
#                         ssid=EXAMPLE_WIRELESS_SSID
#                         scan_ssid=1
#                         key_mgmt=WPA-PSK
#                         psk=a-big-long-wireless-wpa-psk-value
#                     }
