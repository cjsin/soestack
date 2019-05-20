#!stateconf yaml . jinja 

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'elasticsearch' in pillar.svd.cots %}
{%-     set version = pillar.svd.cots.elasticsearch.version %}

.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

.elasticsearch-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: http://nexus:7081/repository/elasticsearch/downloads/elasticsearch/elasticsearch-6.4.0.rpm
        - hash:   {{pillar.svd.cots.elasticsearch.hash}}

.logstash-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: http://nexus:7081/repository/elasticsearch/downloads/logstash/logstash-6.4.0.rpm
        - hash:   {{pillar.svd.cots.logstash.hash}}

.kibana-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: http://nexus:7081/repository/elasticsearch/downloads/kibana/kibana-6.4.0-x86_64.rpm
        - hash:   {{pillar.svd.cots.kibana.hash}}

{%- endif %}
