#!stateconf yaml . jinja

{%- if 'versions' in pillar and 'cots' in pillar.versions and 'edraw' in pillar.versions.cots %}
{%-     set versions  = pillar.versions.cots.edraw %}
{%-     set version   = versions.version %}
{%-     set hash      = versions.hash if 'hash' in versions and versions.hash else '' %}
{%-     set cachefile = '/var/lib/soestack/installers/EdrawMax-'~version~'.run' %}

{%-     if 'interwebs' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['interwebs'] %}

.download-{{baseurl}}/www.edrawsoft.com/archives/EdrawMax-{{version}}.run:
    file.managed:
        - name:            {{cachefile}}
        - source: '{{baseurl}}/www.edrawsoft.com/archives/EdrawMax-{{version}}.run'
        - makedirs:        True
        - user:            root
        - group:           root
        - mode:            755
        - skip_verify:     True

.strip-header-script:
    cmd.run:
        - onlyif: test -f "{{cachefile}}"
        - name: |
            #!/bin/bash
            line_number=$(head -n2 "{{cachefile}}" | tail -n1 | egrep '^line=[0-9][0-9]*$' | cut -d= -f2)
            if [[ -n "${line_number}" ]]
            then
                tail -n +"${line_number}" "{{cachefile}}" > "{{cachefile}}.tar.gz"
                if file "{{cachefile}}.tar.gz" | grep "gzip compressed"
                then
                    echo "OK"
                    exit 0
                else
                    rm -f "{{cachefile}}.tar.gz"
                    rm -f "{{cachefile}}"
                    echo "Unexpected data in archive" 1>&2
                    exit 1
                fi
            else
                rm -f "{{cachefile}}"
                echo "Unexpected data in archive" 1>&2
                exit 1
            fi

# NOTE - salt has a bug which causes tar archive extraction to fail
# when the tar includes a file that has a non ascii character.
# So, the tar command is done manually instead.

#.extract:
#    archive.extracted:
#        - name:    /opt
#        - source:  "{{cachefile}}.tar.gz"
#        - creates: /opt/EdrawMax-9
#        - onlyif:  test -f "{{cachefile}}.tar.gz"

.extract:
    cmd.run:
        - name:    tar -C /opt -xf "{{cachefile}}.tar.gz"
        - unless:  test -d /opt/EdrawMax-9
        - onlyif:  test -f "{{cachefile}}.tar.gz"

{%-     endif %}
{%- endif %}
