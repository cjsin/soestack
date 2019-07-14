{#  this should be ipa_replica - IPA does not have masters, just equal replicas #}
{#  however we are using the term master for an 'initial' server deployment #}
{#  and replica for another server which is joined with an existing master #}
{#  The process for this these days is to install it as a client and then #}
{#  'promote' it by adding it to an 'ipaservers' host group, and then #}
{#  run the ipa-replica-install script (no passwords required) #}
{#  however the firewall and selinux still need to be configured during that process #}

{#- first make sure the client is configured and installed #}
{%  include('templates/deployment/ipa_client/ipa_client.sls') with context %}

{#- then prep it for becoming a server #}
{%  include('templates/deployment/ipa_server/ipa_server.sls') with context %}

{#- perform the promotion if necessary #}
{%  include('templates/deployment/ipa_replica/ipa_replica_promote.sls') with context %}

{#- activate it / make sure services are running, etc #}
{%  include('templates/deployment/ipa_server_activation/ipa_server_activation.sls') with context %}

