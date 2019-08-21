#!stateconf yaml . jinja

.test-script:
    file.managed:
        - name:     /usr/local/bin/logstash-test
        - user:     root
        - group:    root
        - mode:     '0755'
        - contents: |
            #!/bin/bash
            function die()
            {
                echo "ERROR: ${*}" 1>&2
                exit 1
            }
            function usage()
            {
                echo "Usage: ${0##*/} server-or-ip port [tcp|udp]"
                echo ""
                echo "Sends a json message to a logstash service to test it"
                exit 1
            }
            function process_args()
            {
                server="${1}"
                port="${2}"
                proto="${3:-t}"

                [[ -n "${server}" ]] || usage
                
                [[ -n "${port}" ]] || usage
                
                case "${proto}" in 
                    tcp|udp|t|u)
                        proto="${proto:0:1}"
                        ;;
                    *) usage
                esac
            }

            function main()
            {
                local server=""
                local port=""
                local proto=""
                process_args "${@}"

                set -o pipefail
                
                timestamp=$(date)
                host=$(hostname -f)
                index="test-%{YYYY.MM.dd}"
                msg="test"

                data="{ \"index\": \"${index}\", \"timestamp\": \"${timestamp}\", \"host\": \"${host}\", \"message\": \"${msg}\" }"
                
                ipv6=""
                #ipv6="-4"

                /usr/bin/nc ${ipv6} -v "-${proto}" "${server}" "${port}" <<< "${data}"
            }

            main "${@}"


.test:
    cmd.run:
        - name:     /usr/local/bin/logstash-test 0.0.0.0 12345 t
