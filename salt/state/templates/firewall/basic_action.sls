{%- set srcip       = args['from'] if 'from' in args and args['from'] else '' %}
{%- set dstip       = args.ip if 'ip' in args and args.ip else '' %}
{%- set action      = args.action.upper() if ('action' in args and args.action) else 'DENY' %}
{%- set protostr    = args.proto if ('proto' in args and args.proto) else 'tcp' %}
{%- set protos      = proto.split('/') %}
{%- set name_base   = [args.name] if 'name' in args and args.name else [] %}
{%- set sportstr    = args.sport|string if 'sport' in args and args.sport else '' %}
{%- set dportstr    = args.dport|string if 'dport' in args and args.dport else '' %}
{%- set dportrange  = dportstr if dportstr and (':' in dportstr or ',' in dportstr) else '' %}
{%- set sportrange  = sportstr if sportstr and (':' in sportstr or ',' in sportstr) else '' %}
{%- set dportsingle = dportstr if dportstr and not dportrange else '' %}
{%- set sportsingle = sportstr if sportstr and not sportrange else '' %}
{%- set multiport   = dportrange or sportrange %}

{%- if srcip %}
{%-     do name_base.append('s-'~srcip) %}
{%- endif %}
{%- if dstip %}
{%-     do name_base.append('d-'~dstip) %}
{%- endif %}

{%- for proto in protos %}
{%-     set name = [] %}
{%-     do name.extend(name_base) %}
{%-     if proto %}
{%-         do name.append(proto) %}
{%-     endif %}
{%-     do name.append(action) %}

iptables-rule-{{'-'.join(name) }}:
    iptables.insert: 
        # NOTE that the iptables.insert parameters below are order-dependent, and if
        # placed in the wrong order, saltstack will put an invalid '#' in the commandline.

        - table:     {{args.table if 'table' in args and args.table else 'filter'}}
        - chain:     {{args.chain if 'chain' in args and args.chain else 'INPUT'}}
        - position:  1
        - match:     state
        - connstate: NEW
        - protocol:  {{proto}}
        {%- if dstip %}
        - dst:       {{dstip}}
        {%- endif %}
        {%- if srcip %}
        - src:       {{srcip}}
        {%- endif %}
        {%- if not multiport %}
        {%-     if dportsingle %}
        - dport:     {{dportsingle|int}}
        {%-     endif %}
        {%-     if sportsingle %}
        - sport:     {{dportsingle|int}}
        {%-     endif %}
        {%- endif %}
        {%- if multiport %}
        - match:     multiport
        {%-     if dportrange %}
        - dports:    {{dportrange}}
        {%-     endif %}
        {%-     if sportrange %}
        - sports:    {{sportrange}}
        {%-     endif %}
        {%- endif %}
        - jump:      {{action}}
        # Comments are prefixed with SS-rule to allow easy removal
        - comment:   'SS-rule-{{'-'.join(name)}}'
        - save:      True

{#- # end for each proto #}
{%- endfor %}
