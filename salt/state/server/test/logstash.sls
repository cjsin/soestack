#!stateconf yaml . jinja

.test-script:
    file.managed:
        - name:     /usr/local/sbin/logstash-test
        - user:     root
        - group:    root
        - mode:     '0755'
        - contents: |
            #!/bin/bash
            set -o pipefail
            ts=$(date)
            h=$(hostname -f)
            index="test-%{YYYY.MM.dd}"
            msg="test"
            data="{ \"index\": \"${index}\", \"timestamp\": \"${ts}\", \"host\": \"${h}\", \"message\": \"${msg}\" }"
            nc -4 -v -u "${1}" "${2}" <<< "${data}"

