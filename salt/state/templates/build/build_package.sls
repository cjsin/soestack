#
#  Requires 'args' (containing 'pkgname') and there must also be an versions entry in pillar:versions:cots:<pkgname>
#

{%- if 'pkgname' in args and 'build' in pillar and 'rpm' in pillar.build and 'defaults' in pillar.build.rpm and pillar.build.rpm.defaults %}
{%-     set pkgname = args.pkgname %}
{%-     if 'versions' in pillar and 'cots' in pillar.versions and pkgname in pillar.versions.cots and 'version' %}
{%-         set versions_entry = pillar.versions.cots[pkgname] %}
{%-         if 'version' not in versions_entry %}

{{sls}}.build.build_package.{{pkgname}}::no-version-in-versions-entry:
    noop.notice

{%-         endif %}
{%-         if 'version' in versions_entry %}
{%-             set version = versions_entry.version %}
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
{%-                 set hash    = versions_entry.hash if 'hash' in versions_entry else '' %}
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

{{sls}}.build.build_package.{{pkgname}}::no-versions-entry:
    noop.notice

{%-     endif %}
{%- endif %}
