#!stateconf yaml . jinja

web:
    cmd.run:
        - name: |
            curl -s http://{{pillar['service-reg'].gitlab_http}}/ | grep sign_in

registry:
    cmd.run:
        - name: |
            curl -s http://{{pillar['service-reg'].gitlab_docker}}/v2/_catalog | grep -q '"Type":"registry"'

