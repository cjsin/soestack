
#
#        ['192.168.121.103', 'nexus'],
#        ['192.168.121.102', 'wildcard'],
#        ['192.168.121.102', 'nginx'],
#        ['192.168.121.105', 'mattermost'],
#        ['192.168.121.106', 'pages'],
#        ['192.168.121.108', 'grafana'],
#        ['192.168.121.108', 'prometheus'],
#        ['192.168.121.109', 'kibana'],
#        ['192.168.121.109', 'elasticsearch'],
#        ['192.168.121.110', 'master'],
#        ['192.168.121.107', 'gitlab-registry'],
#

{%- set test_records = [
        ['192.168.121.104', 'gitlab'],
    ] %}

{%- for rec in test_records %}
{%-     set ip,name = rec %}

#test-dnsrecord-{{name}}-{{ip}}:
#    saltipa.dnsrecord:
#        - zone:        demo
#        - record_type: arecord
#        - name:        {{name}}
#        - value:       {{ip}}

{%-     set octets = ip.split('.') %}
{%-     if octets|length > 1 %}
{%-         do octets.reverse() %}
{%-         set ptr = octets[0] %}
{%-         set prefix = '.'.join(octets[1:]) %}
{%-         set reverse_zone = prefix ~ '.in-addr.arpa' %}

#test-dnsrecord-reverse-{{reverse_zone}}---ptr-rec-{{ptr}}:
#    saltipa.dnsrecord:
#        - zone:        {{reverse_zone}}
#        - record_type: ptr-rec
#        - name:        {{ptr}}
#        - value:       {{name}}.{{pillar.network.system_domain}}.

{%-     endif %}

{%- if False %}
test-arecord-reverse-{{name}}-{{ip}}:
    saltipa.arecord:
        - zone:        demo
        - name:        {{name}}
        - ip:          {{ip}}
        - add_reverse: True
{%- endif %}

{%- endfor %}

{%- if False %}

{% import 'lib/saltipa.sls' as saltipa with context %}

{{ saltipa.check_ticket() }}

{%- endif %}

test-toplevel-config:
    saltipa.config:
        - ipamaxusernamelength: 32
        - ipasearchtimelimit: 2

test-pwpolicy:
    saltipa.pwpolicy:
        - krbmaxpwdlife: 7776000
        - krbminpwdlife: 3600
        - krbpwdhistorylength: 0
        - krbpwdmindiffchars: 2
        - krbpwdminlength: 2
        - krbpwdmaxfailure: 10
        - krbpwdfailurecountinterval: 60
        - krbpwdlockoutduration: 600
