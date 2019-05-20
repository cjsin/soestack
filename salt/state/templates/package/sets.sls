
#
# Expected context variables:
# 
# args:  a dict with *one of* the following keys/values:
#    
#    - package_set:   <name of a package set>
#    - package_sets:  <array of package set names>
#
# Example pillar data:
#
# package-sets:
#     net-tools:
#         purpose: |
#             provide basic network tools (for example 'route', 'ip')
#         centos,rhel,fedora:
#             - gpm
#
#     kubernetes:
#         purpose: provide kubernetes packages
#         from: kubernetes
#         centos,rhel,fedora:
#             - kubeadm
#             - kubelet
#             - kubectl
#     example:
#         purpose: |
#             Example of packages specifying different repo per OS
#             In this example, centos or rhel will use the 'dockerce' repo
#             but fedora will use any repo available
#         centos,rhel:
#               dockerce:
#                   - docker
#         fedora:
#             - docker
#
# Example salt usage:
#   set args = { 'package_set': 'net-tools' }
#   include('templates/package/sets.sls') with context
#

{%- if 'package_sets' in args 
        or 'package_set' in args
        or 'package_set_names' in args
        or 'package_set_name' in args 
        %}

{#-     # nugget data is merged if available #}
{%-     set ng   = pillar['nugget_data'] if 'nugget_data' in pillar else {} %}
{%-     set ngps = ng['package-sets'] if 'package-sets' in ng else {} %}
{%-     set pps  = pillar['package-sets'] if 'package-sets' in pillar else {} %}

{#-     # Gather the package set names from the template args #}
{%-     set gathered_names = [] %}
{%-     set gathered_objects = [] %}

{%-     if 'package_sets' in args and args.package_sets %}
{%-         do gathered_objects.extend(args.package_sets) %}
{%-     endif %}
{%-     if 'package_set' in args and args.package_set %}
{%-         do gathered_objects.extend([args.package_set]) %}
{%-     endif %}
{%-     if 'package_set_name' in args and args.package_set_name %}
{%-         do gathered_names.extend(args.package_set_name.split(',')) %}
{%-     endif %}
{%-     if 'package_set_names' in args and args.package_set_names %}
{%-         if args.package_set_names is string %}
{%-             do gathered_names.extend(args.package_set_names.split(',')) %}
{%-         else %}
{%-             do gathered_names.extend(args.package_set_names) %}
{%-         endif %}
{%-     endif %}

{%-     for package_set in gathered_objects %}
{#-         # In the case of conflicts, nugget data overrides the pillar package set #}
{%-         set args = { 'package_set': package_set } %}
{%          include('templates/package/set.sls') with context %}
{%-     endfor %}

{%-     for name in gathered_names %}
{#-         # In the case of conflicts, nugget data overrides the pillar package set #}
{%-         if name in ngps %}
{%-             set args = {'package_set_name': name, 'package_set': ngps[name]} %}
{%              include('templates/package/set.sls') with context %}
{%-         elif name in pps %}
{%-             set args = {'package_set_name': name, 'package_set': pps[name]} %}
{%              include('templates/package/set.sls') with context %}
{%-         endif %}
{%-     endfor %}

{#- endif pillar support is available and required args were specified #}
{%- endif %}
