#!stateconf yaml . jinja

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'edraw' in pillar.svd.cots %}
{%-     set svd       = pillar.svd.cots.edraw %}
{%-     set version   = svd.version %}
{%-     set hash      = svd.hash if 'hash' in svd and svd.hash else '' %}
{%-     set cachefile = '/var/lib/soestack/installers/EdrawMax-'~version~'.run' %}

{%-     if 'interwebs' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['interwebs'] %}

.download:
    file.managed:
        - name:            {{cachefile}}
        - source: staruml: {{baseurl}}/www.edrawsoft.com/archives/EdrawMax-{{version}}.run
        - makedirs:        True
        - user:            root
        - group:           root
        - mode:            755

.strip-header-script:
    cmd.run:
        - onlyif: test -f "{{cachefile}}"
        - name:
            #!/bin/bash
            line_number=$(head -n2 "{{cachefile}}" | tail -n1 | egrep '^line=[0-9][0-9]*$' | cut -d= -f2)
            if [[ -n "${line_number}" ]]
            then
                tail -n +"${line_number}" "{{cachefile}}" > "{{cachefile}}.tar.gz"
                if file "{{cachefile}}" | grep "gzip compressed"
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

.extract:
    archive.extracted:
        - name:    /opt
        - source:  "{{cachefile}}"
        - creates: /opt/EdrawMax-9
        - onlyif:  test -f "{{cachefile}}.tar.gz"

{%-     endif %}
{%- endif %}
