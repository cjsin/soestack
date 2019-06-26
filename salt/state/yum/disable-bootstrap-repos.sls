#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            set -e
            cd /etc/yum.repos.d
            mkdir -p disable
            # Care is taken not to disable epel bootstrap repo since the nexus epel repo is broken
            for f in $(ls bootstrap*repo 2> /dev/null | egrep -v epel)
            do
                mv -f "${f}" disable/
            done
            
            #mv -f bootstrap*repo disable/
            for f in /etc/yum.repos.d/CentOS-{Base,Sources,Debuginfo,Vault}.repo 
            do 
                [[ -f "${f}" ]] && mv -f "${f}" disable/
            done
        - onlyif: ls /etc/yum.repos.d | egrep -i '^bootstrap.*[.]repo$|CentOS-(Base|Sources|Debuginfo|Vault)[.]repo$'
