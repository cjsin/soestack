{%- if 'firewall' in args and args.firewall %}
{%-     set name            = args.name if 'name' in args and args.name else '' %}
{%-     set recursion       = args.recursion if 'recursion' in args else [] %}
{%-     if name and name not in recursion %}
{%-         do recursion.append(name) %}
{%-     endif %}

{%-     set prefix, suffix = salt.uuid.ids(args) %}
{%-     set firewall        = args.firewall if 'firewall' in args and args.firewall else {} %}

{%-     if 'firewall-rule-sets' in firewall and 'nugget_data' in pillar and 'firewall-rule-sets' in pillar.nugget_data %}
{%-         set fwrs = pillar.nugget_data['firewall-rule-sets'] %}
{%-         for fw_ruleset_name in firewall['firewall-rule-sets'] %}
{%-             if fw_ruleset_name in fwrs and fw_ruleset_name not in recursion %}
{%-                 with args = { 'firewall': fwrs[fw_ruleset_name], 'name': fw_ruleset_name, 'recursion': recursion } %}
{%                      include('templates/support/firewall.sls') with context %}
{%-                 endwith %}
{%-             endif %}
{%-             do recursion.append(fw_ruleset_name) %}
{%-         endfor %}
{%-     endif %}

{%-     for complexity in [ 'basic', 'complex' ] %}
{%-         if complexity in firewall and firewall[complexity] %}
{%-             for group_name, named_group in firewall[complexity].iteritems() %}
{%-                 with args = { 'prefix': prefix, 'suffix': suffix, 'name': group_name, 'group': named_group } %}
{%                      include('templates/firewall/' ~ complexity ~ '_ruleset.sls') with context %}
{%-                 endwith %}
{%-             endfor %}
{%-         endif %}
{%-     endfor %}
{%- endif %}

