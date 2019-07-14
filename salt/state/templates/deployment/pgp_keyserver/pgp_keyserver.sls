{%- import 'lib/noop.sls' as noop %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set prefix          = 'pgp-server-deployment-' ~ deployment_name %}

{%- set action = args.action if 'action' in args else 'all' %}

{%- with args = {'nugget_name': 'pgp-server', 'required_by': 'pgp_keyserver-deployment'~deployment_name } %}
{%      include('templates/nugget/install.sls') with context %}
{%- endwith %}

{%- if action in [ 'all', 'install' ] %}

# {{sls}}.pgp_keyserver.service-preset-{{prefix}}:
#     file.managed:
#         - name: /etc/systemd/system-preset/99-sks-start-disabled.preset
#         - user: root
#         - group: root
#         - mode:  '0644'
#         - contents: |
#             disable sks-db.service
#             disable sks-recon.service
# {{sls}}.pgp_keyserver.datadir-{{prefix}}:
#     file.directory:
#         - name: /srv/sks
#         - user: sks
#         - group: sks
#         - mode: '0700'
#         - makedirs: True

# {{sls}}.pgp_keyserver.installed-{{prefix}}:
#     pkg.installed:
#         #- fromrepo: epel
#         - pkgs:
#             sks

# {{sls}}.pgp_keyserver.datadir-{{prefix}}:
#     file.directory:
#         - name: /srv/sks
#         - user: sks
#         - group: sks
#         - mode: '0700'
#         - makedirs: True


{%- endif %}

{%- if action in [ 'all', 'configure' ] %}
{%- endif %}

{%- if action in [ 'all', 'activate' ] %}
{%-     set activated = 'activated' in deployment and deployment.activated %}
{%-     for svc in [ 'sks-db', 'sks-recon' ] %}

{{sls}}.pgp_keyserver.{{prefix}}services.{{svc}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{svc}}
        - enable: {{activated}} 

{%-     endfor %}
{%- endif %}

