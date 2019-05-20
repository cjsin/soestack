#
# This template expects the build 'params' to have already been constructed

include:
    - build.prep

{%- set pkgname = params.pkgname %}
{%- set version = params.version %}
{%- set generic_source_url = params.source_url %}
{%- set source_url = generic_source_url|replace('VERSION',version) %}
{%- set subdir     = params.subdir|replace('VERSION',version) if params.subdir else '' %}
{%- do  params.update({'subdir': subdir}) %}
{%- set tmp_builddir = pillar.build.rpm.defaults.tmp_builddir or '/tmp' %}
{%- set savedir      = pillar.build.rpm.defaults.save_folder if 'save_folder' in pillar.build.rpm.defaults and pillar.build.rpm.defaults.save_folder else '/tmp' %} 
{# {%- set tmpdir = salt['temp.dir']('', 'build-' ~ pkgname, ) %} #}

{%- set tmpdir = tmp_builddir ~ '/' ~ pkgname ~ '-build' %}
{%- set build_user = pillar.build.rpm.defaults.build_user or 'nobody' %}


building-package-{{pkgname}}:
    cmd.run:
        - name: |
            echo '{{params|json}}' | jq .

{%- if 'required_packages' in params and params.required_packages %}

build-{{pkgname}}-requirements:
    pkg.installed:
        - pkgs: {{params.required_packages|json}}

{%- endif %}

build-{{pkgname}}-savedir:
    file.directory:
        - name:        '{{savedir}}'
        - makedirs:    True

build-{{pkgname}}-topdir:
    file.directory:
        - name:        '{{tmpdir}}'
        - makedirs:    True

build-{{pkgname}}-topdir-ownership:
    file.directory:
        - name:        '{{tmpdir}}'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'
        - makedirs:    False


build-{{pkgname}}-distdir:
    file.directory:
        - name:        '{{tmpdir}}/dist'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'
        - makedirs:    False

build-{{pkgname}}-rpmdir:
    file.directory:
        - name:        '{{tmpdir}}/rpm'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'

build-{{pkgname}}-archive-extracted:
    archive.extracted:
        - source:      '{{source_url}}'
        - source_hash: '{{params.hash}}'
        - name:        '{{tmpdir}}/extract'
        - user:        '{{build_user}}'
        - group:       '{{build_user}}'

# This is really, really slow - TODO - replace with a chmod command
#build-{{pkgname}}-prepare-for-build:
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

build-{{pkgname}}-prepare-for-build-chmod:
    cmd.run:
        - name: |
            chown -R "{{build_user}}.{{build_user}}" "{{tmpdir}}/extract" "{{tmpdir}}/dist" "{{tmpdir}}/rpm"
            chmod -R "ug-st,o-w" "{{tmpdir}}/extract" "{{tmpdir}}/dist" "{{tmpdir}}/rpm"

# Make sure the top dir is owned by root so that the build-user user cannot modify the script.
# The script will make sure there are no setuid executables in the dist
build-{{pkgname}}-prepare-toplevel:
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

build-{{pkgname}}-create-build-script:
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


build-{{pkgname}}-run-build-script:
    cmd.run:
        - name:     '{{tmpdir}}/build-rpm-package.sh'
        - runas:    '{{build_user}}'
        - onlyif:   test -d '{{tmpdir}}/extract'
        # - watch:
        #    - archive: build-{{pkgname}}-archive-extracted

copy-result:
    cmd.run:
        - name:     cp '{{output_file}}' '{{final_filename}}'
        - onlyif:   test -f '{{output_file}}'

