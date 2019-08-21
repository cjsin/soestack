{#
 # This template expects the build 'params' to have already been constructed
 #}

{%- set pkgname = params.pkgname %}
{%- set version = params.version %}
{%- set generic_source_url = params.source_url %}
{%- set source_url = generic_source_url|replace('VERSION',version) %}
{%- set subdir     = params.subdir|replace('VERSION',version) if params.subdir else '' %}
{%- do  params.update({'subdir': subdir}) %}
{%- set tmp_builddir = pillar.build.rpm.defaults.tmp_builddir or '/tmp/ss-builds' %}
{%- set savedir      = pillar.build.rpm.defaults.save_folder if 'save_folder' in pillar.build.rpm.defaults and pillar.build.rpm.defaults.save_folder else '/tmp' %} 
{# {%- set tmpdir = salt['temp.dir']('', 'build-' ~ pkgname, ) %} #}
{%- set clean = False if 'clean' in params and not params.clean else True %}
{%- set tmpdir = tmp_builddir ~ '/' ~ pkgname ~ '-build' %}
{%- set build_user = pillar.build.rpm.defaults.build_user or 'nobody' %}


{{sls}}.build.rpm_package.{{pkgname}}:
    noop.notice:
        - text: |
            {{params|json}}

{%- if 'required_packages' in params and params.required_packages %}

{{sls}}.build.rpm_package.{{pkgname}}.requirements:
    pkg.installed:
        - pkgs: {{params.required_packages|json}}

{%- endif %}

{%- if clean %}

{#-     # As a safety check, only delete paths more than 4 dirs deep #}
{%-     if tmpdir and tmpdir.split('/')|length > 3 %}

{{sls}}.build.rpm_package.{{pkgname}}.clean.tmpdir:
    file.absent:
        - name: '{{tmpdir}}'

{%-     endif %}
{%- endif %}

{{sls}}.build.rpm_package.{{pkgname}}.ss-work-dir:
    file.directory:
        - name:        /var/lib/soestack
        - makedirs:    True
        - user:        root
        - group:       root 
        - mode:        '0755'

{{sls}}.build.rpm_package.{{pkgname}}.savedir:
    file.directory:
        - name:        '{{savedir}}'
        - makedirs:    True
        - user:        root
        - group:       root 
        - mode:        '0755'

{{sls}}.build.rpm_package.{{pkgname}}.tmp-builddir:
    file.directory:
        - name:        '{{tmp_builddir}}'
        - makedirs:    True
        - user:        root
        - group:       root 
        - mode:        '0755'

{{sls}}.build.rpm_package.{{pkgname}}.logdir:
    file.directory:
        - name:        /var/log/build
        - makedirs:    True
        - user:        root
        - group:       root 
        - mode:        '0755'

{{sls}}.build.rpm_package.{{pkgname}}.topdir:
    file.directory:
        - name:        '{{tmpdir}}'
        - makedirs:    True
        - user:        root
        - group:       root 
        - mode:        '0755'

{{sls}}.build.rpm_package.{{pkgname}}.topdir-ownership:
    file.directory:
        - name:        '{{tmpdir}}'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'
        - makedirs:    False


{{sls}}.build.rpm_package.{{pkgname}}.distdir:
    file.directory:
        - name:        '{{tmpdir}}/dist'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'
        - makedirs:    False

{{sls}}.build.rpm_package.{{pkgname}}.rpmdir:
    file.directory:
        - name:        '{{tmpdir}}/rpm'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'

{{sls}}.build.rpm_package.{{pkgname}}.archive-extracted:
    archive.extracted:
        - source:      '{{source_url}}'
        - source_hash: '{{params.hash}}'
        - name:        '{{tmpdir}}/extract'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'

# This is really, really slow - TODO - replace with a chmod command
#{{sls}}.build.rpm_package.{{pkgname}}.prepare-for-build:
#    file.directory:
#        - name:      "{{tmpdir}}"
#        - onlyif:    test -d "{{tmpdir}}/extract"
#        - user:      {{build_user}}
#        - group:     {{build_user}}
#        - file_mode: '0745'
#        - dir_mode:  '0755'
#        - recurse:
#            - user
#            - group
#            - mode

{{sls}}.build.rpm_package.{{pkgname}}.prepare-for-build-chmod:
    cmd.run:
        - name: |
            chown -R "{{build_user}}.{{build_user}}" "{{tmpdir}}/extract" "{{tmpdir}}/dist" "{{tmpdir}}/rpm"
            chmod -R "ug-st,o-w" "{{tmpdir}}/extract" "{{tmpdir}}/dist" "{{tmpdir}}/rpm"

# Make sure the top dir is owned by root so that the build-user user cannot modify the script.
# The script will make sure there are no setuid executables in the dist
{{sls}}.build.rpm_package.{{pkgname}}.prepare-toplevel:
    file.directory:
        - name:       '{{tmpdir}}'
        - user:       root
        - group:      root
        - file_mode:  '0745'
        - dir_mode:   '0755'

{%- set arch           = 'x86_64' %}
{%- set filename_base  = '-'.join([pkgname,version,params.rpm_version ~ params.rpm_vendorsuffix])  %}
{%- set rand_tag       = salt['random'].get_str(8) %}
{%- set suffix         = '.'.join(['',arch,'rpm']) %}
{%- set final_filename = ''.join([savedir, '/',    filename_base,suffix]) %}
{%- set output_file    = ''.join([tmpdir,  '/rpm/',filename_base,'.',rand_tag,suffix]) %}

{{sls}}.build.rpm_package.{{pkgname}}.create-build-script:
    file.managed:
        - name:           '{{tmpdir}}/build-rpm-package.sh'
        - source:         salt://scripts/build-rpm-package.sh.jinja
        - template:       jinja
        - user:           root
        - group:          root
        - mode:           '755'
        - context:  
            paths:
                source:   '{{tmpdir}}/extract'
                dist:     '{{tmpdir}}/dist'
                rpm:      '{{tmpdir}}/rpm'
                outfile:  '{{output_file}}'
            params:       {{params|json}}
            clean:        {{'0' if not clean else '1'}}

{{sls}}.build.rpm_package.{{pkgname}}.run-build-script:
    cmd.run:
        - name:     '{{tmpdir}}/build-rpm-package.sh'
        - runas:    '{{build_user}}'
        - onlyif:   test -d '{{tmpdir}}/extract'
        # - watch:
        #    - archive: build-{{pkgname}}-archive-extracted

{{sls}}.build.rpm_package.{{pkgname}}.extraction-fail:
    cmd.run:
        - name:     "echo FAIL: {{tmpdir}}/extract' was not extracted"
        - unless:   test -d '{{tmpdir}}/extract'

{{sls}}.build.rpm_package.{{pkgname}}.copy-result:
    cmd.run:
        - name:     cp '{{output_file}}' '{{final_filename}}'
        - onlyif:   test -f '{{output_file}}'

{{sls}}.build.rpm_package.{{pkgname}}.copy-result-fail:
    cmd.run:
        - name:     "echo FAIL: '{{output_file}}' was not generated; /bin/false"
        - unless:   test -f '{{output_file}}'


{{sls}}.build.rpm_package.{{pkgname}}.upload:
    cmd.run:
        - name:     built-rpm-upload '{{final_filename}}'
        - onlyif:   test -f '{{final_filename}}'
        - require:
            - cmd: {{sls}}.build.rpm_package.{{pkgname}}.run-build-script
            - cmd: {{sls}}.build.rpm_package.{{pkgname}}.copy-result
