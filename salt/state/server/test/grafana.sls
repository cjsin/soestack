#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            curl -s http://{{pillar['service-reg'].grafana}}/status | grep -q grafana-app
