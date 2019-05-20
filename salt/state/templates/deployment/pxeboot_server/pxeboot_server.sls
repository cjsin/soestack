{%- import 'lib/noop.sls' as noop %}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set deployment_type = args.deployment_type %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set prefix = 'pxeboot-server-deployment-' ~ deployment_name %}

{%- set action = args.action if 'action' in args else 'all' %}

{%- with args = {'nugget_name': 'pxeboot-server', 'required_by': 'pxeboot_server-deployment'~deployment_name } %}
{%      include('templates/nugget/install.sls') with context %}
{%- endwith %}


{%- set paths   = config.paths   if 'paths' in config else {} %}

{#- # these three - tftpdir,nfsdir,isodir, can be an absolute path #}
{%- set tftpdir = paths.tftp     if 'tftp'  in paths and paths.tftp is defined else '/var/lib/tftpboot' %}
{%- set nfsdir  = paths.nfs      if 'nfs'   in paths and paths.nfs is defined else '/var/lib/tftpboot' %}
{%- set isodir  = paths.isos     if 'isos'  in paths and paths.isos is defined else '' %}

{#- # pxedir is a path relative to tftpdir #}
{%- set pxedir  = paths.pxe      if 'pxe'   in paths and paths.pxe is defined else 'pxelinux' %}
{#- # cfgdir is a path relative to pxedir #}
{%- set cfgdir  = paths.cfgs     if 'cfgs'  in paths and paths.cfgs is defined else '/pxelinux.cfg' %}
{#- # the osdir is a path relative to the nfsdir #}
{%- set osdir   = paths.os       if 'os'    in paths and paths.os is defined else 'os' %}
{%- set lans    = config.lans    if 'lans'  in config and config.lans else {} %}
{%- set lan_defaults = lans.defaults if 'defaults' in lans and lans.defaults else { 'entries': [] } %}

{%- set isos    = config.isos    if 'isos'  in config else [] %}

{%- set hostdata_lookup = salt['pillar.get'](config.hostdata,{}) if 'hostdata' in config and config.hostdata is string else {} %}
{%- set hostdata = hostdata_lookup if hostdata_lookup else (config.hostdata if ('hostdata' in config and config.hostdata) else {}) %}
{%- set diagnostics = False %}

{%- set client_names = [] %}

{%- if 'clients' in config %}
{%-     do client_names.extend(config.clients) %}
{%- elif hostdata %}
{%-     for hostname,hostinfo in hostdata %}
{%-         if 'type' in hostinfo and hostinfo.type == 'client' %}
{%-             do client_names.append(hostname) %}
{%-         endif %}
{%-     endfor %}
{%- endif %}

{%- set pxe_server = config.server if ('server' in config and config.server) else (grains.fqdn_ip4[0] if 'fqdn_ip4' in grains and grains.fqdn_ip4 else '') %}
{%- set http_server = config.server if ('http_server' in config and config.http_server) else (grains.fqdn_ip4[0] if 'fqdn_ip4' in grains and grains.fqdn_ip4 else '') %}
{%- set nfs_server = config.server if ('nfs_server' in config and config.nfs_server) else (grains.fqdn_ip4[0] if 'fqdn_ip4' in grains and grains.fqdn_ip4 else '') %}

{%- if action in [ 'all', 'install' ] %}

.{{prefix}}-tools-installed:
    pkg.installed:
        - pkgs: 
            - genisoimage

{%- endif %}

{%- if action in [ 'all', 'configure' ] %}

{%- if isos and isodir %}

.{{prefix}}-iso-extract:
    file.managed:
        - name:   /usr/local/sbin/iso-extract
        - user:   root
        - group:  root
        - mode:   '0755'
        - source: salt://{{slspath}}/iso-extract.sh.jinja

{%- else %}

.{{prefix}}-no-isos-or-isodir-configured:
    cmd.run:
        - name: |
            echo "Either the ISOs path (key paths.isos), or a list of ISO files (key isos) "
            echo "have not been configured within the deployments.pxeboot_server.{{deployment_name}}.config"

{%- endif %}

{%- for iso_shortname,isofile in config.isos.iteritems() %}
{%-     set isopath = isodir ~ '/' ~ isofile %}
{%-     set extractpath = nfsdir ~ '/' ~ osdir ~ '/' ~ iso_shortname %}

.{{prefix}}-iso-extracted-{{iso_shortname}}:
    cmd.run:
        - name:   /usr/local/sbin/iso-extract "{{isopath}}" "{{extractpath}}"
        - unless: test -f "{{extractpath}}/images/pxeboot/initrd.img"

{%- endfor %}

.{{prefix}}-setup-pxe-boot-files:
    cmd.script:
        - source: salt://{{slspath}}/pxedir-prepare.sh.jinja
        - template: jinja
        - context: 
            # Note these must be quoted in case one is an empty string
            tftpdir: '{{tftpdir}}'
            pxedir:  '{{pxedir}}'
            cfgdir:  '{{cfgdir}}'
            osdir:   '{{osdir}}'
            syslinux: /usr/share/syslinux
        - unless: test -f {{tftpdir}}/{{pxedir}}/pxelinux.0

{%- set interfaces = [] %}
{%- set lans = { } %}

{%- if 'lans' in config and config.lans %}
{%-     for lan_name,data in config.lans.iteritems() %}
{#-         # a LAN can't be customised unless its subnet is defined #}
{%-         if lan_name == 'defaults' or 'subnet' in data and data.subnet and data.subnet|regex_match('^([0-9].*)') %}
{%-             do lans.update({lan_name : data }) %}
{%-             set iface = data.iface if 'iface' in data else '' %}
{%-             if iface and iface not in interfaces %}
{%-                 do interfaces.append(iface) %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}
{%- endif %}

.{{prefix}}-dnsmasq-conf:
    file.managed:
        - name: /etc/dnsmasq.d/99-pxeboot-{{deployment_name}}.conf
        - user:  root
        - group: root
        - mode: '0644'
        - template: jinja
        - source: salt://{{slspath}}/dnsmasq.conf.jinja
        - context: 
            tftpdir:       {{tftpdir}}
            interfaces:    {{interfaces|json}}
            lans:          {{lans|json}}
            hostdata:      {{hostdata|json}}
            client_names:  {{client_names|json}}
            pxe_server:    {{pxe_server}}


#.{{prefix}}-boot-menu-defaults:
#    file.managed:
#        - name:     '{{tftpdir}}/{{pxedir}}/{{cfgdir}}/default.base'
#        - user:     root
#        - group:    root
#        - mode:     '0644'
#        - source:   salt://{{slspath}}/pxemenu.jinja
#        - template: jinja
#        - context: 
#            entries: {}

{%- for lan_name,lan in lans.iteritems() %}
{%-     set debug = ["lan " ~ lan_name] %}
{%-     set timeout = lan.timeout if 'timeout' in lan else (lan_defaults.timeout if 'timeout' in lan_defaults else 0) %}
{%-     set menufile_name = 'default' if lan_name == 'defaults' else 'defaults-'~lan_name %}
{%-     set bootfile = '/'.join([tftpdir,pxedir,cfgdir,menufile_name]) %}

{#- # build entry data from the defaults plus the lan overrides #}

{#-     what a mess jinja makes, with its unmodifiable objects #}
{%-     set data_base = { 
            'append': [],
            'timeout': 0,
            'kernel': '',
            'initrd': '', 
            'title': '', 
            'server': pxe_server,
            'http_server': http_server, 
            'nfs_server': nfs_server 
            } %}

{#-     entry names list is used to maintain the original order #}
{%-     set incompatible_message = ' is incompatible with the data type inherited from the lan spec or lan defaults, and has replaced it' %}
{%-     set incompatible=[] %}
{%-     set entry_names = [] %}
{%-     set entries = {} %}
{%-     for outer in [ 'simple', 'entries' ] %}
{%-         do debug.append('  outer '~outer) %}
{%-         do debug.append('  starting this iteration with data_base keys '~ ' '.join(data_base.keys())) %}
{%-         for inner in [ 'defaults', 'lan' ] %}
{%-           if lan_name == 'defaults' and inner == 'lan' %}
{%-               do debug.append('    skip inner iteration for defaults (no point)' ) %}
{%-           else %}
{%-             do debug.append('    obj '~inner) %}
{%-             set obj = lan_defaults if inner == 'defaults' else lan %}
{%-             do debug.append('    obj ' ~ inner ~ ' has keys ' ~ ','.join(obj.keys()))  %}
{%-             for subkey,value in obj.iteritems() %}
{#-                 # entries are handled separately below #}
{%-                 if outer == 'simple' %}
{%-                     do debug.append('      simple subkey '~subkey) %}
{%-                     if subkey not in [ 'entries', 'append' ] %}
{%-                         do debug.append('        update data_base simple subkey '~subkey~ ' with new value ' ~ value ~ ' in data_base') %}
{%-                         do data_base.update({subkey: value}) %}
{%-                     endif %}
{%-                     if subkey == 'append' %}
{%-                         if value is string %}
{%-                             do debug.append('        append to  data_base[append] subkey with new value ' ~ value ~ ' in data_base.append') %}
{%-                             do data_base.append.append(value) %}
{%-                         elif value is iterable and value is not mapping %}
{%-                             do debug.append('        extend to data_base [append] subkey with new list value ' ~ value ~ ' in data_base.append') %}
{%-                             do data_base.append.extend(value) %}
{%-                         endif %}
{%-                     endif %}
{%-                 endif %}
{%-                 if outer == 'entries' %}
{%-                     if subkey == 'entries' and value %}
{%-                         do debug.append('      entries subkey') %}
{%-                         do debug.append('        subkey '~subkey) %}
{%-                         for entry_name, entry in value.iteritems() %}
{%-                             do debug.append('          entry_name '~entry_name) %}
{%-                             set this_entry = {} %}
{%-                             if entry_name not in entry_names %}
{%-                                 do debug.append('            this is a new entry name - appending to entry_names') %}
{%-                                 do entry_names.append(entry_name) %}
{#-                                 # This is a new entry so flow into it first some values the base object #}
{%-                                 do debug.append('            preload new entry with values from data_base') %}
{%-                                 do this_entry.update(data_base) %}
{%-                                 do debug.append('            keys in this entry after preloading are ' ~ ' '.join(this_entry.keys())) %}
{%-                                 do debug.append('            value of "append" after preloading is ' ~ ' '.join(this_entry.append)) %}
{%-                             else %}
{%-                                 do debug.append('            existing entry - update this new one with values from the old one') %}
{%-                                 do this_entry.update(entries[entry_name]) %}
{%-                             endif %}
{%-                             if entry %}
{%-                               do debug.append('            adding data in entry ') %}
{#-                               # do some subkey merging, merging maps and lists instead of replacing them #}
{%-                               for entry_subkey_name, entry_subkey_value in entry.iteritems() %}
{%-                                 do debug.append('              processing entry subkey '~entry_subkey_name) %}
{%-                                 if entry_subkey_value == None or entry_subkey_value is string or entry_subkey_name not in this_entry %}
{%-                                     do debug.append('                  replace inherited value (this value is None or a string or it is a new key') %}
{%-                                     do this_entry.update({entry_subkey_name: entry_subkey_value}) %}
{%-                                 else %}
{%-                                     set prior_value = this_entry[entry_subkey_name]  %}
{%-                                     if entry_subkey_value is mapping %}
{%-                                         if prior_value is not mapping  %}
{#-                                             # incompatible types for merging - so just replace the inherited value #}
{%-                                             do debug.append('                  replace inherited value (new value type mapping is incompatible with inherited)') %}
{%-                                             do incompatible.append(' '.join(['lan',lan_name,'entry',entry_name,'key',entry_subkey_name, incompatible_message])) %}
{%-                                             do this_entry.update({entry_subkey_name: entry_subkey_value}) %}
{%-                                         else %}
{%-                                             do debug.append('                  update within inherited value (new value type mapping is compatible with inherited)') %}
{%-                                             do this_entry[entry_subkey_name].update(entry_subkey_value) %}
{%-                                         endif %}
{%-                                     elif entry_subkey_value is iterable %}
{#-                                         # this value is iterable but not a mapping and not a string, treat it as a list #}
{#-                                         # so discard any prior value that is a mapping or a string #}
{#-                                         # but append new items if the prior was a list #}
{%-                                         if prior_value is string or prior_value is mapping %}
{%-                                             do debug.append('                  replace inherited value (new value type list is incompatible with inherited mapping or string)') %}
{%-                                             do this_entry.update({entry_subkey_name : entry_subkey_value})%}
{%-                                             do incompatible.append(' '.join(['lan',lan_name,'entry',entry_name,'key',entry_subkey_name, incompatible_message])) %}
{%-                                         else %}
{%-                                             do debug.append('                  extend inherited value (new value type list is compatible with inherited)') %}
{%-                                             do this_entry[entry_subkey_name].extend(entry_subkey_value) %}
{%-                                         endif %}
{%-                                     endif %}
{%-                                 endif %}
{%-                               endfor %}
{%-                             endif %}
{%-                             do entries.update({entry_name : this_entry}) %}
{%-                         endfor %}
{%-                     endif %}
{%-                 endif %}
{%-             endfor %}
{%-           endif %}

{%-         endfor %}

{%-     endfor %}

{%-     set lanconfig = {} %}
{%-     do lanconfig.update(data_base) %}
{%-     set ordered_entries = [] %}
{%-     for entry_name in entry_names %}
{%-         set named_entry = {} %}
{%-         do named_entry.update(entries[entry_name]) %}
{%-         do named_entry.update({'name': entry_name}) %}
{%-         do ordered_entries.append(named_entry) %}
{%-     endfor %}


{%-     if incompatible %}
.{{prefix}}-WARNINGS-{{lan_name}}:
    cmd.run:
        - name: |
            echo "WARNING:"
            {%- for m in incompatible %}
            echo '{{m}}'
            {%- endfor %}
{%-     endif %}

{%-     if 'ss_provisioning' in lan and lan.ss_provisioning and 'provisioning' in config and config.provisioning %}
{%-         set provisioning = config.provisioning %}

{%-         if 'scripts' in provisioning and provisioning.scripts %}

.{{prefix}}-require-rsync-{{lan_name}}:
    pkg.installed:
        - name: rsync

.{{prefix}}-outofdate-helper-{{lan_name}}:
    file.managed:
        - name:   /usr/local/sbin/rsync-uptodate
        - user:   root
        - group:  root
        - mode:   '0755'
        - source: salt://{{slspath}}/rsync-uptodate.sh

.{{prefix}}-update-ss-provisioning-{{lan_name}}:
    cmd.run:
        - name:   |
            echo "Check:"
            /usr/local/sbin/rsync-uptodate dry '/{{provisioning.scripts}}/' '/{{tftpdir}}/{{lan.ss_provisioning}}/'  '/provision'
            echo "Actual:"
            /usr/local/sbin/rsync-uptodate real '/{{provisioning.scripts}}/' '/{{tftpdir}}/{{lan.ss_provisioning}}/'  '/provision'
        - unless: /usr/local/sbin/rsync-uptodate dry '/{{provisioning.scripts}}/' '/{{tftpdir}}/{{lan.ss_provisioning}}/'  '/provision'

{%-             if 'pw' in provisioning and provisioning.pw %}

provisioning-pw-{{lan_name}}:
    file.managed:
        - name:     '{{tftpdir}}/{{lan.ss_provisioning}}/common/inc/provisioning-passwords.sh'
        - user:     root 
        - group:    root
        - mode:     '0660'
        - contents: |
            ROOT_PW='{{provisioning.pw.root if 'root' in provisioning.pw else '' }}'
            GRUB_PW='{{provisioning.pw.grub if 'grub' in provisioning.pw else '' }}'
            SSH_PW='{{provisioning.pw.ssh if 'ssh' in provisioning.pw else '' }}'

{%-             endif %}

{%-         endif %}
{%-     endif %}

.{{prefix}}-boot-menu-{{lan_name}}:
    file.managed:
        - name:     {{bootfile}}
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://{{slspath}}/pxemenu.jinja
        - template: jinja
        - context: 
            is_default: {{lan_name == 'defaults'}}
            lan_name:   {{lan_name}}
            # The toplevel defaults
            defaults:   {{lan_defaults|json}}
            # The lan config 
            lan:        {{lan|json}}
            # The merged config
            config:     {{lanconfig|json}}
            # The merged entries
            entries:    {{ordered_entries|json}}

{%-     if 'subnet' in lan and lan.subnet %}
{%-         set subnet_ip_prefix=lan.subnet %}
{#-         # convert the lan to hex nibbles #}
{%-         set octets = subnet_ip_prefix.split('.') %}
{%-         set nibbles = [] %}
{%-         for o in octets %}
{%-             set twonibbles = '%02x' % (o|int) %}
{%-             do nibbles.append(twonibbles) %}
{%-         endfor %}
{%-         set hexstr = ''.join(nibbles) %}

.{{prefix}}-symlink-boot-menu-{{lan_name}}-{{hexstr}}:
    file.symlink:
        - name:    {{tftpdir}}/{{pxedir}}/{{cfgdir}}/{{hexstr}}
        - target: 'defaults-{{lan_name}}'

{%-     endif %}

{#- # end for each lan #}
{%- endfor %}


{#- # end if configure action #}
{%- endif %}

{%- if action in [ 'all', 'activate' ] %}

# Nothing to do here - the required services should have been activated as dependencies

{%-     set activated = 'activated' in deployment and deployment.activated %}

{%-     for svc in [ 'dnsmasq', 'simple-http-pxe' ] %}

{{prefix}}-service-{{svc}}:
    service.{{'running' if activated else 'dead'}}:
        - name:   {{svc}}
        - enable: {{activated}} 

{%-     endfor %}

{%-     for svc in [ 'nfs-server' ] %}
{%-         if activated %}
{{prefix}}-service-{{svc}}:
    service.running:
        - name:   {{svc}}
        - enable: True 
{%-         endif %}
{%-     endfor %}

{%- endif %}

