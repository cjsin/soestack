
{%- if 'svd' in pillar and 'cots' in pillar.svd and 'elasticsearch' in pillar.svd.cots %}
{%-     set version = pillar.svd.cots.elasticsearch.version %}

.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

.elasticsearch-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: http://nexus:7081/repository/elasticsearch/downloads/elasticsearch/elasticsearch-{{version}}.rpm
        - hash:   {{pillar.svd.cots.elasticsearch.hash}}

{%- endif %}
