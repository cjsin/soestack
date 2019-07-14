{#  this should be ipa_master - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}

{#- first configure as a generic server, not activated or deployed #}
{#- at this point, it could be intended as a master or as a client to be promoted to a replica #}
{%  include('templates/deployment/ipa_server/ipa_server.sls') with context %}

{#- run the inital deployment/setup script for the initial master #}
{%  include('templates/deployment/ipa_master/ipa_master_deploy.sls') with context %}

{#- activate / start it up #}
{%  include('templates/deployment/ipa_server/ipa_server_activation.sls') with context %}
