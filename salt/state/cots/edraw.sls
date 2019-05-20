#!stateconf yaml . jinja

.:
    pkg.installed:
        - source: edraw: http://nexus:7081/repository/interwebs/www.edrawsoft.com/archives/EdrawMax-9-64.run

#!stateconf yaml . jinja

{%- set cachefile = /var/lib/soestack/installers/EdrawMax-9-64.run %}

.download:
    file.managed:
        - name:            {{cachefile}}
        - makedirs:        True
        - source: staruml: http://nexus:7081/repository/interwebs/www.edrawsoft.com/archives/EdrawMax-9-64.run
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
                return 0
                else
                    rm -f "{{cachefile}}.tar.gz"
                    rm -f "{{cachefile}}"
                    echo "Unexpected data in archive" 1>&2
                    return 1
                fi
            else
                rm -f "{{cachefile}}"
                echo "Unexpected data in archive" 1>&2
            fi

.extract:
    archive.extracted:
        - name: /opt
        - source:  "{{cachefile}}"
        - creates: /opt/EdrawMax-9
        - onlyif: test -f "{{cachefile}}.tar.gz"
