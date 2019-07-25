{#
#
# This template expects the following context variables:
#   - args: a dict with the following key/value pairs:
#       - service_name  - the name of the service
#       - container     - an object describing the image,mounts,user,group,ports,entrypoint options
#
#}

{%- set suffix          = args.suffix if 'suffix' in args else salt['uuids.short']() %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment_type = args.deployment_type %}

{%- set container_defaults = {
    'mounts': {},
    'storage': [],
    'user': 'root',
    'group': 'root',
    'image': '',
    'ports': '',
    'volumes': '',
    'options': '',
    'entrypoint': '',
    'docker_options': ''
} %}

{%- set container = {} %}
{%- set deployment_container = deployment.container if 'container' in deployment and deployment.container else {} %}
{%- do container.update(container_defaults) %}
{%- do container.update(deployment_container) %}
{%- set service_name = deployment_name %}

{%- set prefix = 'containerized-service-' ~ service_name ~ '-' ~ suffix %}
{%- set image_parts_colon = container.image.split(':') %}
{%- set image_parts_slash = container.image.split('/') %}

{%- set action = args.action if 'action' in args else 'all' %}

{#- if there is a colon before a slash, then the image already includes a server host:port prefix #}
{%- if image_parts_colon[0] and (image_parts_colon[0]|length < image_parts_slash[0]|length) %}
{%-     set image_prefix = '' %}
{%- elif 'local_image' in container and container.local_image %}
{#-     # the image is configured to use a locally loaded container #}
{%-     set image_prefix = '' %}
{%- elif 'service-reg' in pillar and pillar['service-reg'] and 'default_registry' in pillar['service-reg'] and pillar['service-reg'].default_registry %}
{%-     set image_prefix = pillar['service-reg'].default_registry ~ '/' %}
{%- else %}
{%-     set image_prefix = '' %}
{%- endif %}

{% import 'lib/docker.sls' as docker %}

{%- if action in [ 'all', 'install' ] %}

{{docker.image_present(container.image,image_prefix=image_prefix) }}

{# This line is required to fix a salt bug which appends stray 'f' characters to macros #}

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{{sls}}.containerized_service.{{service_name}}.systemd-unit:
    file.managed:
        - name:     /etc/systemd/system/{{service_name}}.service
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - source:   salt://templates/deployment/containerized_service/systemd-service.jinja
        - context:
            service_name: {{service_name}}
            container:    {{container|json()}}
            # NOTE the image prefix must be quoted because otherwise an empty value is turned into a None
            image_prefix: '{{image_prefix}}'

{{sls}}.containerized_service.{{service_name}}.sysconfig:
    file.managed:
        - name:     /etc/sysconfig/{{service_name}}
        - user:     root
        - group:    root
        - mode:     '0640'
        - source:   salt://templates/deployment/containerized_service/sysconfig.jinja
        - template: jinja
        - context:
            service_name: '{{service_name}}'
            container:    {{container|json}}
            # NOTE the image prefix must be quoted because otherwise an empty value is turned into a None
            image_prefix: '{{image_prefix}}'

{%-     set container_fs_spec = {} %}
{%-     if False %}
{#-          # When saltstack 2108.3.3 comes out the traverse filter will be available #}
{%-         set fs_defaults = deployment | traverse('filesystem:defaults', {}) %}
{%-     else %}
{%-         set fs = deployment.filesystem if 'filesystem' in deployment and deployment.filesystem else {} %}
{%-         set fs_defaults = fs.defaults if 'defaults' in fs and fs.defaults else {} %}
{%-     endif %}

{%-     do container_fs_spec.update(fs_defaults) %}
{%-     for key in [ 'user', 'group', 'mode', 'dir_mode', 'file_mode' ] %}
{%-         if key in container %}
{%-             do container_fs_spec.update({key: container[key]})%}
{%-         elif key in deployment %}
{%-             do container_fs_spec.update({key: deployment[key]})%}
{%-         endif %}
{%-     endfor %}

{%-     if 'storage' in container and container.storage %}
{%-         for item_path in container.storage %}
{%-             set spec = { 'makedirs': True, 'selinux': 'container_file_t' } %}
{%-             do spec.update(container_fs_spec) %}
{%-             with args = { 'prefix': prefix ~ '-storage', 'path': item_path, 'item_type': 'dir', 'spec': spec } %}
{%                  include('templates/support/fsitem.sls') with context %}
{%-             endwith %}
{%-         endfor %}
{%-     endif %}

{%-     if 'mounts' in container and container.mounts %}
{%-         for iteration in [ 'dir', 'file' ] %}
{%-             for item_path, item_type in container.mounts.iteritems() %}
{%-                 if iteration == item_type %}
{%-                     set spec = { 'makedirs': True, 'selinux': 'container_file_t' } %}
{%-                     do spec.update(container_fs_spec) %}
{%-                     with args = { 'prefix': prefix ~ '-mount-'~item_type, 'path': item_path, 'item_type': item_type, 'spec': spec } %}
{%                          include('templates/support/fsitem.sls') with context %}
{%-                     endwith %}
{%-                 endif %}
{%-             endfor %}
{%-         endfor %}
{%-     endif %}

{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

{%-     set activated = 'activated' in deployment and deployment.activated %}

{{sls}}.containerized_service.{{service_name}}.service:
    service.{{'running' if activated else 'dead'}}:
        - name: {{ service_name}}
        - enable: {{activated}} 

{%- endif %}
