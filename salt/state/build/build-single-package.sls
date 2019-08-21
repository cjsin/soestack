{%- if 'cmdline-args' in pillar and pillar['cmdline-args'] and 'build-single-package' in pillar['cmdline-args']  %}
{%-     set cmdline_args = pillar['cmdline-args']['build-single-package'] %}
{%-     if 'pkgname' in cmdline_args and cmdline_args.pkgname %}
{%-         if 'build' in pillar and 'rpm' in pillar.build and pillar.build.rpm %}
{%-             set clean = True if 'clean' in cmdline_args and cmdline_args['clean'] else False %}

include:
    - build.prep

{%-             with args = {'pkgname': cmdline_args.pkgname, 'clean': clean } %}
{%                  include('templates/build/build_package.sls') with context %}
{%-             endwith %}
{%-         endif %}
{%-     endif %}
{%- endif %}
