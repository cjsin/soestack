#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            curl -s https://{{pillar['service-reg'].ipa_https}}/
