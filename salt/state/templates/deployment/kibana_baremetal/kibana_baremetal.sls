
{%- if 'svd' in pillar and 'cots' in pillar.svd and 'kibana' in pillar.svd.cots %}
{%-     set version = pillar.svd.cots.kibana.version %}

.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

.kibana-direct-download:
    pkg.installed:
        - sources: 
            - kibana: http://nexus:7081/repository/elasticsearch/downloads/kibana/kibana-{{version}}-x86_64.rpm
        - hash:   {{pillar.svd.cots.kibana.hash}}

{%- endif %}
