#!stateconf yaml . jinja 

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'elasticsearch' in pillar.svd.cots %}
{%-     set svd = pillar.svd.cots.elasticsearch %}
{%-     set version = svd.version %}
{%-     set hash    = svd.hash if 'hash' in svd else '' %}
{%-     if 'elasticsearch' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls.elasticsearch %}

.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

.elasticsearch-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{baseurl}}/downloads/elasticsearch/elasticsearch-{{version}}.rpm
        - hash:   {{hash}}

.logstash-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{baseurl}}/downloads/logstash/logstash-{{version}}.rpm
        - hash:   {{hash}}

.kibana-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{baseurl}}/downloads/kibana/kibana-{{version}}-x86_64.rpm
        - hash:   {{hash}}

{%- else %}


.no-repository-configured:
    noop.notice:
        - text: There is no nexus repository configured for elastic.co downloads

{%- endif %}
