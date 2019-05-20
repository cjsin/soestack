#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            curl -s http://{{grains.host}}:{{pillar.node_exporter.port}}/metrics | head -n1

