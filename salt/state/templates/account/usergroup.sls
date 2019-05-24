{#- this template requires an 'args' mapping with some of the following data in it #}

{%- set prefix, suffix  = salt.uuid.ids(args) %}

{%- set username  = args.user %}
{%- set uid       = args.uid      if 'uid'      in args and args.uid      else '' %}
{%- set groupname = args.group    if 'group'    in args and args.group    else username %}
{%- set gid       = args.gid      if 'gid'      in args and args.gid      else uid %}
{%- set system    = args.system   if 'system'   in args and args.system   else False %}
{%- set fullname  = args.fullname if 'fullname' in args and args.fullname else username %}
{%- set shell     = args.shell    if 'shell'    in args and args.shell    else '/sbin/nologin' %}
{%- set home      = args.home     if 'home'     in args and args.home     else '' %}
{%- set groups    = args.groups   if 'groups'   in args and args.groups   else [] %}

{%- set all_groups = [] %}
{%- do all_groups.extend(groups) %}
{%- if groupname %}
{%-     do all_groups.append(groupname) %}
{%- endif %}

{# Create groups manually until I can get the jinja template include to find the right path  #}

{%- if groupname %}

{{sls}}.account.usergroup.{{prefix}}group-{{groupname}}{{suffix}}:
    group.present:
        - name:     {{groupname}}
        {%- if system %}
        - system:   True
        {%- endif %}
        {%- if gid %}
        - gid:      {{gid}}
        {%- endif %}

{%- endif %}

{{sls}}.account.usergroup.{{prefix}}user-account-{{username}}{{suffix}}:
    user.present:
        - name:     {{username}}
        {%- if fullname %}
        - fullname: {{fullname}}
        {%- endif %}
        {%- if system %}
        - system:   True
        {%- endif %}
        {%- if uid %}
        - uid:      {{uid}}
        {%- endif %}
        {%- if shell %}
        - shell:    {{shell}}
        {%- endif %}
        {%- if home %}
        - home:     {{home}}
        - createhome: False
        {%- endif %}
        {%- if all_groups %}
        - groups:
            {%- for group in groups %}
            - {{group}}
            {%- endfor %}
        {%- endif %}


