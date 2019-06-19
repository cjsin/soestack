#!stateconf yaml . jinja

# Silence salt errors by installing a couple of pip packages

include:
    - common.pip

{# Unfortunately python2 pip is only available for RedHat/CentOS through the EPEL repos, which are currently broken due to them changing to use zchunk metadata which is not supported through nexus #}
{%- if False %}

.pip-installed:
    pkg.installed:
        - pkgs:
            - python2-pip

.silence-boto-errors:
    cmd.run:
        - name:   pip install boto boto3
        - unless: pip list | grep boto

{%- endif %}
