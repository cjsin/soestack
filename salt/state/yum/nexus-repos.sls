# Example data structure
# nexus-repos:
#     defaults:
#         kubernetes: True 
#         ius:
#             enabled: 0
#     # Redhat and centos are both so crappy and ancient
#     # that they both need these three
#     redhat,centos:
#         rpmfusion:
#             enabled: 0 
#         epel:       True
#     centos:
#         centos:     True
#     fedora:
#         fedora:     True

{%- set diagnostics = False %}
{%- if 'nexus-repos' in pillar and pillar['nexus-repos'] and 'nexus' in pillar and pillar.nexus and 'repos' in pillar.nexus and pillar.nexus.repos %}
{%-     set nexus = pillar.nexus %}
{%-     set nexusrepos = pillar['nexus-repos'] %}
{%-     set default_selection = nexusrepos.defaults if 'defaults' in nexusrepos else {} %}
{%-     set selected = { } %}
{%-     do selected.update(default_selection) %}
{%-     for subkey, data in nexusrepos.iteritems() %}
{%-         if subkey != 'defaults' %}
{%-             if grains.os.lower() in subkey.lower().split(',') %}
{%-                 if data is mapping %}
{%-                     for nexus_reponame,repodata in data.iteritems() %}
{%-                         if repodata is mapping %}
{%-                             do selected.update({nexus_reponame: repodata})%}
{%-                         elif repodata == True %}
{%-                             do selected.update({nexus_reponame: True }) %}
{%-                         elif repodata == False %}
{%-                             do selected.pop(nexus_reponame) %}
{%-                         endif %}
{%-                     endfor %}
{%-                 endif %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}

{%- for expect in [ ['minrate','0'],['timeout','600'], ['ip_resolve','4'], ['fastestmirror','0'] ] %}

{%-     set expect_text= expect[0] ~ '='~ expect[1] %}
.fix-yum-for-mirror-use-{{expect[0]}}:
    cmd.run:
        - name:   sed -i -e '/{{expect[0]}}/ d' -e '$ p; n; a {{expect_text}}' /etc/yum.conf
        - unless: grep -q '{{expect_text}}' /etc/yum.conf
{%- endfor %}

{%- if diagnostics %}
.selected-nexus-repos-for-os-{{grains.os}}:
    noop.notice:
        - text: |
            {{selected|json}}
{%- endif %}

{#-     # we now have a consolidated list of what should be enabled or disabled #}
{#-     # and will iterate over all the defined nexus repos #}
{#-     # It is done in these two stages to make sure we can delete the repo files #}
{#-     # when a repo which was previously enabled becomes disabled. #}
{%-     for nexus_reponame, nexus_repodata in pillar.nexus.repos.iteritems() %}
{%-         if 'format' in nexus_repodata 
                and nexus_repodata.format == 'yum' 
                and 'yum' in nexus_repodata 
                and nexus_repodata.yum 
                %}
{%-             set nexus_yum_repodata = nexus_repodata.yum %}
{%-             set create_files = nexus_reponame in selected %}

{%-             set base_repodata={
                    'description':yum_reponame,
                    'path':'',
                    'enabled': 0, 
                    'gpgcheck': 0, 
                    'gpgkey': '',
                    } %}

{#-             The attributes can be overriden here within the 'yum' key, and also #}
{#-             later, within the os-specific subkey, and finally in each individual yum repository  #}
{#-             that is defined for that operating system #}
{%-             for validkey in base_repodata.keys() %}
{%-                 if validkey in nexus_yum_repodata %}
{%-                     do base_repodata.update({validkey: nexus_yum_repodata[validkey]}) %}

        
{%-                 endif %}
{%-             endfor %}
{%-             for subkey_name,subkey_data in nexus_yum_repodata.iteritems() %}


{%-                 if subkey_data is mapping and 'repos' in subkey_data and subkey_data.repos and grains.os.lower() in subkey_name.lower().split(',') %}


{%-                     set os_data = subkey_data %}
{%-                     set os_repodata={} %}
{%-                     for validkey in base_repodata.keys() %}
{%-                         if validkey in os_data  %}
{%-                             do os_repodata.update({validkey: os_data[validkey]}) %}

{%-                         endif %}
{%-                     endfor %}
{%-                     for yum_reponame,yum_repodata in subkey_data.repos.iteritems() %}
{%-                         set yum_repo_file = '/etc/yum.repos.d/' ~ nexus_reponame ~ '-' ~ yum_reponame ~ '.repo' %}
{%-                         if create_files %}
{%-                             set this_repodata = {} %}
{%-                             do  this_repodata.update(base_repodata) %}
{%-                             do  this_repodata.update(os_repodata) %}
{%-                             do  this_repodata.update(yum_repodata) %}
{%-                             set overrides = selected[nexus_reponame] %}
{%-                             if overrides is mapping %}
{%-                                 do this_repodata.update(overrides) %}
{%-                             endif %}
{%-                             set base_url = 'http://'~ nexus.http_address + '/repository/' ~ nexus_reponame ~ '/' ~ this_repodata.path %}
.create-nexus-{{nexus_reponame}}-repo-{{yum_reponame}}:
    file.managed:
        - name:     '{{yum_repo_file}}'
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            [{{yum_reponame}}]
            name={{yum_reponame}}
            description={{this_repodata.description}} generated for nexus repo {{nexus_reponame}} subkey {{subkey_name}}, {{yum_reponame}}
            baseurl={{base_url}}
            #enabled={{'1' if yum_reponame in ['os','updates'] else '0'}}
            enabled={{'1' if this_repodata.enabled or yum_reponame in ['os','updates'] else '0'}}
            gpgcheck=0
            #gpgkey={{'file:///etc/pki/rpm-gpg/'~this_repodata.gpgkey if this_repodata.gpgkey else ''}}
            
{%-                         else %}

{#-                         # end if create or delete #}
{%-                         endif %}
{#-                     # end for each yum_reponame #}
{%-                     endfor %}
{%-                 else %}

{%- if diagnostics %}
.abc-{{nexus_reponame}}-{{subkey_name}}:
   noop.notice:
       - text: |
           either test failed for subkey_data is mapping for nexus reponame {{nexus_reponame}} and subkey_name {{subkey_name}}
           or else yum is not inside subkey_data or else the yum subkey is empty
           the subkey data is {{subkey_name}} = {{subkey_data|json}}
{%- endif %}

{#-                 # end if subkey data is a mapping with a yum subkey and the subkey matches the OS name #}
{%-                 endif %}
{#-             # end foreach subkey in nexus_repodata #}
{%-             endfor %}
{%-         else %}

{%- if diagnostics %}
.repo-type-for-{{nexus_reponame}}-is-not-yum:
    noop.notice:
        - text: |
            {{nexus_repodata|json()}}

{%- endif %}

{#-         # end if the nexus repo format is yum #}
{%-         endif %}
{#-     # end foreach nexus_reponame #}
{%-     endfor %}
{#-     # end if create or delete #}
{%- endif %}

