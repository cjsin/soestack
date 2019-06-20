#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            set -e
            cd /etc/yum.repos.d
            mkdir -p disable
            # Care is taken not to disable epel bootstrap repo since the nexus epel repo is broken
            for f in $(ls bootstrap*repo|egrep -v epel)
            do
                mv -f "${f}" disable/
            done
            #mv -f /etc/yum.repos.d/bootstrap*repo /etc/yum.repos.d/disable/
        - onlyif: ls /etc/yum.repos.d | egrep -i '^bootstrap.*[.]repo$'
