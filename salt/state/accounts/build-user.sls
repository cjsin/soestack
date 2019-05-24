#!stateconf yaml . jinja
{%- if 'build' in pillar and 'rpm' in pillar.build and 'defaults' in pillar.build.rpm and 'build_user' in pillar.build.rpm.defaults %}
{%-     set defaults = pillar.build.rpm.defaults %}
{%-     set build_user = defaults.build_user if 'build_user' in defaults and defaults.build_user else 'nobody' %}
{%-     if build_user %}

# First make sure the home directory is accessible by the user
# ie that the parent folders exist and are readable
.create-user-homedir-path-with-parents:
    file.directory:
        - name:       '{{pillar.build.rpm.defaults.tmp_builddir}}'
        - unless:     test -d '{{pillar.build.rpm.defaults.tmp_builddir}}'
        - makedirs:   True
        - user:       root
        - group:      root
        - mode:       '0755'

.create-user-homedir-path:
    file.directory:
        - name:       '{{pillar.build.rpm.defaults.tmp_builddir}}'
        - user:       '{{build_user}}'
        - group:      '{{build_user}}'
        - mode:       '0755'

{%-         if build_user != 'nobody' %}

.user-account-build-user:
    user.present:
        - name:       '{{build_user}}'
        - home:       '{{pillar.build.rpm.defaults.tmp_builddir}}'
        - system:     True
        - createhome: True

{%-         endif %}
{%-     endif %}
{%- endif %}
