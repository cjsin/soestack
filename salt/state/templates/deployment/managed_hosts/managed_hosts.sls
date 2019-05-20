{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}
{%- set config          = deployment.config if 'config' in deployment else {} %}
{%- set domain          = config.domain if 'domain' in config else '' %}
{%- set dot_domain      = '.' ~ domain if domain else '' %}
{%- set hosts_key       = config.hosts if 'hosts' in config and config.hosts else '' %}
{%- set use_ipa         = config.ipa   if 'ipa'   in config and config.ipa else False %}
{%- set hosts           = salt['pillar.get'](hosts_key,[]) %}
{%- set state_tag       = deployment_type ~ '-' ~ deployment_name %}
{%- set prefix          = state_tag ~ '-' %}
{%- set action          = args.action if 'action' in args else 'all' %}
{%- set debug           = [] %}
{%- set diagnostics     = False %}

{#  this should be ipa_master - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}

{%- set deployment_type = args.deployment_type %}

{%- if action in [ 'all', 'configure' ] %}

{%- if not hosts %}

{{prefix}}no-hosts-found:
    cmd.run:
        - name: echo "No hosts found in {{hosts_key}} for this deployment." 

{%- else %}

{%-     set hostdata = {} %}
{%-     for hostname, props in hosts.iteritems() %}
{%-         set fqdn = hostname ~ dot_domain if '.' not in hostname else hostname %}
{%-         set type = props.type if 'type' in props and props.type else 'dns' %}
{%-         set mac = props.mac if 'mac' in props and props.mac else '' %}
{%-         set aliases = props.aliases if 'aliases' in props and props.aliases else '' %}
{%-         set aliases_str = aliases if aliases is string else " ".join(aliases) %}
{%-         set ip = props.ip if 'ip' in props and props.ip else '' %}
{%-         set hostfile_value = props.hostfile if 'hostfile' in props and props.hostfile else None %}
{%-         set hostfile_map = hostfile_value if hostfile_value and hostfile_value is mapping else {} %}
{%-         set hostfile_list = hostfile_value if hostfile_value and not hostfile_map and hostfile_value is not string else [] %}
{%-         set hostfile_name = hostfile_value if hostfile_value and hostfile_value is string else '' %}
{%-         if hostfile_name %}
{%-             do hostfile_list.append(hostfile_name) %}
{%-         endif %}
{%-         if hostfile_list %}
{%-             for name in hostfile_list %}
{%-                 do hostfile_map.update({name : True} ) %}
{%-                 do debug.append("Added "~name~" to hostfile map")%}
{%-             endfor %}
{%-         endif %}
{%-         set update_hostfile_matches = [] %}
{%-         for regex,value in hostfile_map.iteritems() %}
{%-             do debug.append('check ' ~ regex ~ ' against ' ~ grains.host) %}
{#-              # NOTE the regex has to be surrounded by a capture group (parentheses) or else no result will be returned from the filter #}
{%-             if regex == grains.host or grains.host|regex_search('('~regex~')', ignorecase=True) %}
{%-                 do update_hostfile_matches.append(value) %}
{%-                 do debug.append("matched regex " ~ regex ~ ", appending value " ~ value) %}
{%-             else %}
{%-                 do debug.append("No match for " ~ grains.host ~ " against " ~ regex) %}
{%-                 do debug.append(grains.host~"|regex_search("~regex~") == " ~ grains.host|regex_search(regex,ignorecase=True) ) %}
{%-             endif %}
{%-         endfor %}

{%-         set update_hostfile = True in update_hostfile_matches %}
{%-         if ip %}
{%-             if ip in hostdata %}
{%-                 set entry = hostdata[ip] %}
{%-                 do entry.update({'aliases': entry['aliases'] ~ ' '~ fqdn ~ ' ' ~ aliases, 'update_hostfile': entry['update_hostfile'] or update_hostfile }) %}
{%-                 if mac and not entry['mac']%}
{%-                     do entry.update({'mac': mac}) %}
{%-                 endif %}
{%-                 if (type and not entry['type']) or (type == 'client' and entry['type'] != type) %}
{%-                     do entry.update({'type': type}) %}
{%-                 endif %}
{%-                 if (type and not entry['type']) or (type == 'client' and entry['type'] != type) %}
{%-                     do entry.update({'type': type}) %}
{%-                 endif %}
{%-                 do hostdata.update({ip: entry })%}
{%-             else %}
{%-                 set entry = {'ip': ip, 'fqdn': fqdn, 'aliases': aliases, 'type': type, 'mac': mac, 'update_hostfile': update_hostfile } %}
{%-                 do hostdata.update({ip: entry}) %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}

{{prefix}}ss-hosts-file:
    file.managed:
        - name:     /etc/ss-hosts-{{deployment_name}}
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            {%- for ip, props in hostdata.iteritems() %}
            {{ip}} {{props.fqdn}} {{props.aliases}} # {{props.type}} {{props.mac}}
            {%- endfor %}

{%- if use_ipa %}
{%-     for ip, props in hostdata.iteritems() %}

{{prefix}}ipa-dns-records-{{ip}}-{{props.fqdn}}:
    saltipa.arecord:
        - fqdn:            {{props.fqdn}}
        - ip:              {{ip}} 
        - add_reverse:     True
        - update_existing: False
    
{%- if 'aliases' in props and props.aliases %} 
{{prefix}}ipa-dns-records-fqdn-aliases-{{ip}}-{{props.aliases}}:
    saltipa.cnames:
        - name:            {{props.fqdn}}
        - aliases:         {{props.aliases}}
{%- endif %}

{%-     endfor %}
{%- endif %}

{%-     for ip,props in hostdata.iteritems() %}
{%-         if props.update_hostfile %}
{%-             set host_line = ip ~ ' ' ~ props.fqdn ~ ' ' ~ props.aliases %}

{{prefix}}etc-hosts-{{ip}}:
    cmd.run:
        - name:   sed -r -i -e '/^[[:space:]]*{{ip}}([[:space:]]|$)/ d' -e '$ a{{host_line}}' /etc/hosts
        - unless: grep "{{host_line}}" /etc/hosts
        
{%-         endif %}
{%-     endfor %}

{#- # end if hosts #}
{%- endif %}

{%- if diagnostics %}

{{prefix}}-debug}}:
    cmd.run:
        - name: |
            echo 'debug strings'
            echo '{{debug|json}}' | jq .
            echo  '{{ 'infra' | regex_search('(.*)', ignorecase=True) }}'

{%- endif %}

{#- # configure action #}
{%- endif %}
