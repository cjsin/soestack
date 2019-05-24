#
#  Requires 'args' (containing 'pkgname') and there must also be an svd entry in pillar:svd:cots:<pkgname>
#

{%- if 'pkgname' in args and 'build' in pillar and 'rpm' in pillar.build and 'defaults' in pillar.build.rpm and pillar.build.rpm.defaults %}
{%-     set pkgname = args.pkgname %}
{%-     if 'svd' in pillar and 'cots' in pillar.svd and pkgname in pillar.svd.cots and 'version' %}
{%-         set svd_entry = pillar.svd.cots[pkgname] %}
{%-         if 'version' not in svd_entry %}

{{sls}}.build.build_package.{{pkgname}}::no-version-in-svd-entry:
    noop.notice

{%-         endif %}
{%-         if 'version' in svd_entry %}
{%-             set version = svd_entry.version %}
{%-             set build_settings = pillar.build.rpm %}
{%-             set build_defaults = build_settings.defaults %}

{%-             set package_build_params = build_settings[pkgname] if pkgname in build_settings else {} %}

{%-             if not package_build_params %}

{{sls}}.build.build_package.{{pkgname}}::No build parameters defined for package:
    noop.notice

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

{{sls}}.build.build_package.{{pkgname}}:
    noop.error:
        - text: |
            No source url was defined!
            {{params|json}}

{%-             endif %}
{%-         endif %}
{%-     else %}

{{sls}}.build.build_package.{{pkgname}}::no-svd-entry:
    noop.notice

{%-     endif %}
{%- endif %}
