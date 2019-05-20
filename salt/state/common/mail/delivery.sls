include:
    {%- if grains.os in ['CentOS','RedHat'] %}
    - .postfix
    {%- elif grains.os in ['Fedora'] %}
    - .esmtp
    {%- endif %}
