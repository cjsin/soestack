{%- set prefix, suffix  = salt.uuid.ids() %}
{%- set package_set_name = args.package_set_name %}
{%- set package_set = args.package_set %}


{#- # action can be 'absent', or another saltstack supported mode ('installed','latest') #}
{%- set action = args.action if 'action' in args else package_set.action if 'action' in package_set else 'installed' %}
{%- set fromrepo = package_set.from if 'from' in package_set else 'any' %}

{%- for subkey, data in package_set.iteritems() %}

{#-     # Documentation key 'purpose' and metadata key 'from' are ignored during iteration #}
{%-     if subkey not in [ 'purpose', 'from', 'action' ] %}

{#-         # The current node operating system is matched against the key which #}
{#-         # can be a comma separated list of operating system names #}
{%-         if grains.os.lower() in subkey.lower().split(',') %}

{#-             # The operating system matched, so add the specified packages #}
{#-             # A set of repo: <package-list> is gathered #}
{#-             # where the repo will default to 'fromrepo' above, if not specified #}
{#-             # NOTE jinja has no way of creating an ordered dict, to maintain a #}
{#-             #   deterministic order as defined in the yaml #}
{#-             #   so we use here a dict and an ordered array of the keys #}
{%-             set specified_order  = data['order'].split(',') if 'order' in data else [] %}
{%-             set reposets = {} %}
{%-             set reposets_order = [] %}
{%-             if data is mapping %}
{#-                 # If the data is a mapping(dict) then the key is the repo and the value is the package name list #}
{%-                 for rs_key, rs_item in data.iteritems() %}
{%-                     if rs_key not in ['order'] %}
{%-                         do reposets.update({rs_key: rs_item}) %}
{%-                         do reposets_order.append(rs_key) %}
{%-                     endif %}
{%-                 endfor %}
{%-             elif data is string %}
{#-                 # If it is a string then should be a single package name #}
{%-                 do reposets.update({fromrepo : [data]}) %}
{%-                 do reposets_order.append(fromrepo) %}
{%-             elif data is iterable %}
{#-                 # Otherwise it is a list of packages, from the repo specified in the 'from' subkey #}
{%-                 do reposets.update({fromrepo : data}) %}
{%-                 do reposets_order.append(fromrepo) %}
{%-             endif %}

{%-             set use_order = specified_order if specified_order else reposets_order %}
{%-             for repo_name in use_order %}
{%-                 set package_list = reposets[repo_name] %}
{%-                 set groups = [] %}
{%-                 set regular_pkgs = [] %}
{%-                 for item in package_list %}
{%-                     if item %}
{%-                         if item[0] == '@' %}
{%-                             do groups.append(item[1:]) %}
{%-                         else %}
{%-                             do regular_pkgs.append(item) %}
{%-                         endif %}
{%-                     endif %}
{%-                 endfor %}

{%-                 if groups %}
{%-                     if action == 'absent' %}

{{sls}}.set.error-group-uninstalls-not-supported-for-{{package_set_name}}-{{repo_name}}:
    noop.error

{%-                     else %}
{%-                         for group_name in groups %}

#install-package-set-{{package_set_name}}-{{repo_name}}-groupinstalls-{{group_name}}-{{suffix}}:
#    pkg.group_installed:
#        {%- if repo_name != 'any' %}
#        - fromrepo: {{repo_name}}
#        {%- endif %}
#       - name: {{group_name}}

# Salt has a bug which they don't seem to care to fix in over 3 years,
# whereby it is completely unable to install package groups with yum
# if the package group in any way intersects with the gnome desktop
# on a redhat,centos,fedora based system because the pkg module does
# not properly handle recursive dependencies and it does not correctly
# handle the mismatched results that the yum groupinfo command returns
# (yum groupinfo gnome-desktop returns results for gnome-desktop and gnome-desktop-environment 
# and the group_installed code only handles one type of result at a time).

{{sls}}.set.install-package-set-{{package_set_name}}-{{repo_name}}-groupinstalls-{{group_name}}-{{suffix}}:
    cmd.run:
        - name: yum -y {%if repo_name != 'any' %}--enablerepo='{{repo_name}}'{%endif%} groupinstall '{{group_name}}' && yum group mark install "{{group_name}}"
        - unless: yum group list installed | egrep '[[:space:]]{{group_name}}$'

{%-                         endfor %}
{%-                     endif %}
{%-                 endif %}

{%-                 if regular_pkgs %}

{{sls}}.set.install-package-set-{{package_set_name}}-{{repo_name}}-{{suffix}}:
    pkg.{{'removed' if action == 'absent' else action}}:
        {%- if repo_name != 'any' %}
        - fromrepo: {{repo_name}}
        {%- endif %}
        - pkgs: 
            {%- for p in regular_pkgs %}
            {%-     if p and p[0] != '@' %}
            - {{p}}
            {%-     endif %}
            {%- endfor %}

{#-                 # end if there are normal packages (not groups) #}
{%-                 endif %}
{#-             end for each repo #}
{%-             endfor %}
{#-         endif operating system matches this subkey #}
{%-         endif %}
{#-     endif subkey is not purpose or fromrepo #}
{%-     endif %}
{#- end for each subkey #}
{%- endfor %}
