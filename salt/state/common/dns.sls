#!stateconf yaml . jinja

{%- set dns           = pillar.dns            if 'dns' in pillar and pillar.dns else {} %}
{%- set network       = pillar.network        if 'network' in pillar and pillar.network else {} %}
{%- set search        = dns.search            if 'search' in dns and dns.search else {} %}
{%- set nameservers   = dns.nameservers       if 'nameservers' in dns and dns.nameservers else {} %}
{%- set system_domain = network.system_domain if 'system_domain' in network and network.system_domain else '' %}
{%- set server        = dns.server            if 'server'        in dns and dns.server else '' %}
{%- set own_fqdn      = grains.host + '.' + system_domain %}
{%- set is_server     = server and server in [grains.host, own_fqdn] %}

{#- # This configuration is done using dicts rather than arrays #}
{#- # So that it can be overridden on a server #}
{#- # Unfortunately the pillar dicts are iterated over in a different order #}
{#- # when using iteritems() despite them being an ordered dict. Not sure why. #}
{#- # (I've never seen this in using salt for 3 years, but it's happening now...) #}
{#- # So we have to sort the keys and access by key #}

{%- if dns and (search or nameservers or system_domain) %}
{%-     set search_domains = [] %}
{%-     set nameserver_ips = [] %}
{%-     for item in nameservers.keys()|sort %}
{%-         if nameservers[item] %}
{%-             do nameserver_ips.append(nameservers[item]) %}
{%-         endif %}
{%-     endfor %}
{%-     for item in search.keys()|sort %}
{%-         if search[item] %}
{%-             do search_domains.append(search[item]) %}
{%-         endif %}
{%-     endfor %}

.etc-resolv-conf:
    file.managed:
        - name:     /etc/resolv.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            {%- if system_domain and not search %}
            domain {{system_domain}}
            {%- endif %}
            {%- if search %}
            search {{' '.join(search_domains) }}
            {%- endif %}
            {%- if is_server and '127.0.0.1' not in nameserver_ips %}
            nameserver 127.0.0.1 
            {%- endif %}
            {%- for item in nameserver_ips %}
            nameserver {{item}}
            {%- endfor %}
{%- endif %}
