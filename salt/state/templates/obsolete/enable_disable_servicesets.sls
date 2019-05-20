# Obsolete

{%- if ('service_sets' in args or 'service_set' in args)  %}

{#-     # action can be 'enabled','disabled', or another saltstack supported mode ('running','dead') #}
{%-     set action = args.action if 'action' in args else 'enabled' %}

{#-     # nugget data is merged if available #}
{%-     set ng   = pillar['nugget_data'] if 'nugget_data' in pillar else {} %}
{%-     set ngss = ng['service-sets'] if 'service-sets' in ng else {} %}
{%-     set pss  = pillar['service-sets'] if 'service-sets' in pillar else {} %}

{#-     # Gather the package set names from the template args #}
{%-     set gathered = [] %}

{%-     if 'service_sets' in args %}
{%-         if args.service_sets is not string %}
{%-             do gathered.extend(args.service_sets) %}
{%-         else %}
{%-             do gathered.extend(args.service_sets.split(',')) %}
{%-         endif %}
{%-     elif 'service_set' in args %}
{%-         do gathered.extend([args.service_set]) %}
{%-     endif %}

{%-     for name in gathered %}
{#-         # In the case of conflicts, nugget data overrides the pillar package set #}
{%-         if name in ngss %}
{%-             set args = {'service_set_name': name, 'service_set': ngss[name]} %}
{%              include('templates/install_service_set.sls') with context %}
{%-         elif name in pss %}
{%-             set args = {'service_set_name': name, 'service_set': pss[name]} %}
{%              include('templates/install_service_set.sls') with context %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
