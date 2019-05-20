#
#  Requires 'args' (containing 'pkgname') and there must also be an svd entry in pillar:svd:cots:<pkgname>
#

{%- if 'pkgname' in args and 'build' in pillar and 'rpm' in pillar.build and 'defaults' in pillar.build.rpm and pillar.build.rpm.defaults %}
{%-     set pkgname = args.pkgname %}
{%-     if 'svd' in pillar and 'cots' in pillar.svd and pkgname in pillar.svd.cots and 'version' %}
{%-         set svd_entry = pillar.svd.cots[pkgname] %}
{%-         if 'version' not in svd_entry %}

echo building-package-{{pkgname}}-no-version-in-svd-entry:
    cmd.run

{%-         endif %}
{%-         if 'version' in svd_entry %}
{%-             set version = svd_entry.version %}
{%-             set build_settings = pillar.build.rpm %}
{%-             set build_defaults = build_settings.defaults %}

{%-             set package_build_params = build_settings[pkgname] if pkgname in build_settings else {} %}

{%-             if not package_build_params %}

echo No build parameters defined for package {{pkgname}}:
    cmd.run

{%-             endif %}

{%-             set params = {} %}
{%-             do params.update(build_defaults) %}
{%-             do params.update({
                    'rpm_summary':      pkgname ~ ' ' ~ version ~ ' built for SoeStack',
                    'package_license':  params.license if ( 'license' in params and params.license) else 'unknown',
                    'package_version':  version,
                    'version':          version,
                }) %}
{%-             do params.update(package_build_params) %}
{%-             do params.update({'pkgname': pkgname, 'version': version }) %}
{%-             if 'source_url' in params and params.source_url %}
{%-                 set hash    = svd_entry.hash if 'hash' in svd_entry else '' %}
{%-                 do params.update({'hash': hash}) %}
{%                  include('templates/build/build_rpm_package.sls') with context %}
{%-             else %}

.build-package-{{pkgname}}:
    cmd.run:
        - name: |
            echo "No source url was defined!" 1>&2
            echo "{{params|json}}"
            exit 1

{%-             endif %}
{%-         endif %}
{%-     else %}

echo building-package-{{pkgname}}-no-svd-entry:
    cmd.run

{%-     endif %}
{%- endif %}
