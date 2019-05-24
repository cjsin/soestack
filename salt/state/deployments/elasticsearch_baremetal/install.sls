#!stateconf yaml . jinja 

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'elasticsearch' in pillar.svd.cots %}
{%-     set svd = pillar.svd.cots.elasticsearch %}
{%-     set version = svd.version %}
{%-     set hash    = svd.hash if 'hash' in svd else '' %}
{%-     set baseurl = 'http://nexus:7081/repository/elasticsearch/downloads' %}

.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

.elasticsearch-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{baseurl}}/elasticsearch/elasticsearch-{{version}}.rpm
        - hash:   {{hash}}

.logstash-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{baseurl}}/logstash/logstash-{{version}}.rpm
        - hash:   {{hash}}

.kibana-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{baseurl}}/kibana/kibana-{{version}}-x86_64.rpm
        - hash:   {{hash}}

{%- endif %}
