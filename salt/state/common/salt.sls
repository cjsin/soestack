#!stateconf yaml . jinja

# Silence salt errors by installing a couple of pip packages

include:
    - common.pip

.pip-installed:
    pkg.installed:
        - pkgs:
            - python2-pip

.silence-boto-errors:
    cmd.run:
        - name:   pip install boto boto3
        - unless: pip list | grep boto
