{%- import 'lib/noop.sls' as noop %}

{%- set diagnostics     = False %}
{%- set prefix, suffix  = salt.uuid.ids(args) %}
{%- set required_by     = '-by-' ~ args.required_by if 'required_by' in args else '-by-none' %}
{%- set nugget_name     = args.nugget_name if 'nugget_name' in args else '' %}
{%- set suffix          = nugget_name ~ required_by ~ suffix %}
{%- set pillar_location = args.pillar_location if 'pillar_location' in args else 'nuggets:'~nugget_name %}
{%- set action          = args.action if 'action' in args and args.action else '' %}

{# Process the arg 'nugget' and use it if provided - otherwise look up the nugget in pillar based on the name #}
{%- if 'nugget' not in args %}
{#      # need to lookup the nugget by name #}
{%-     set nugget = pillar.nuggets[nugget_name] if nugget_name in pillar.nuggets else {} %}
{%- else %}
{#      # already have a nugget #}
{%-     set nugget = args.nugget %}
{%- endif %}

{#- at this point we have a nugget defined, or else it failed to be found and was not specified #}

{%- if diagnostics %}
{{noop.notice('Processing nugget ' ~ nugget_name ~ ' action ' ~ action) }}
{%- endif %}

{#- note that we want to allow empty nuggets here as they are useful for inheritance relationships #}
{#- so a warning is only printed if the nugget was not found at all #}
{%- if not (nugget is defined) %}
{{noop.warning('Nugget not found - ' ~ nugget_name)}}
{%- endif %}

{%- if nugget %}

{%-     if not action %}

{{noop.error('No action defined while processing nugget')}}

{%-     elif action not in nugget or not nugget[action] %}

{%- if diagnostics %}
{{noop.notice('No '~ action ~ ' data defined while processing nugget '~ nugget_name) }}
{%- endif %}

{%-     elif action in nugget and nugget[action] %}

{%-         set data = nugget[action] %}

{%-         if 'nuggets-required' in data %}
{%-             with args = { 'nugget_name': nugget_name, 'nugget': nugget, 'action': action, 'required': data['nuggets-required'] } %}
{%                  include('templates/nugget/recurse.sls') with context %}
{%-             endwith %}
{%-         endif %}

{%-         if action == 'install' %}
{%-             if 'installed' in data or 'uninstalled' in data %}
{%-                 with args = { 'parent': data } %}
{%                      include('templates/support/packagesets.sls') with context %}
{%-                 endwith %}
{%-             endif %}
{%-         endif %}

{%-         if action == 'activate' %}
{%-             if 'services' in data or 'service-sets' in data %}
{%-                 with args = { 'parent': data } %}
{%                      include('templates/support/services.sls') with context %}
{%-                 endwith %}
{%-             endif %}

{%-             if 'firewall' in data and data.firewall %}
{%-                 with args = { 'firewall': data.firewall } %}
{%                      include('templates/support/firewall.sls') with context %}
{%-                 endwith %}
{%-             else %}
{%- if diagnostics %}
{{noop.notice('no firewall data within activate') }}
{%- endif %}
{%-             endif %}
{%-         endif %}
{%-     endif %}

{#-     in the configure stage, process the filesystem settings #}
{%-     if action == 'configure' %}
{#-         # process filesystem objects that are always updated #}
{%-         if 'filesystem' in nugget and nugget.filesystem %}
{%-             with args = { 'parent': nugget.filesystem, 'pillar_location' : pillar_location } %}
{%                  include('templates/support/filesystem.sls') with context %}
{%-            endwith %}
{%-         endif %}
{%-     endif %}

{%- endif %}
