#!stateconf yaml . jinja

.:
    cmd.script:
        - onlyif: ls /etc/yum.repos.d | egrep -i '^bootstrap.*[.]repo$|CentOS-(Base|Sources|Debuginfo|Vault)[.]repo$'
        - source: salt://{{slspath}}/disable-bootstrap-repos.sh.jinja
        - template: jinja

