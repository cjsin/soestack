#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            curl -s http://{{pillar['service-reg'].prometheus}}/status | grep -q '>Version<'
