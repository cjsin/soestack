.. _soestack_structure:

##################
SoeStack Structure
##################

The SoeStack SOE is designed to be installed on an infrastructure server which will act as a Salt master and PXE boot server for building and controlling other nodes.

.. _structure_toplevel:

Toplevel Structure
##################

``provision`` - Initial provisioning of nodes is performed utilising the code and configuration within the ``provision`` subdirectory.

``salt`` - After the initial stages of provisioning, SaltStack configuration from within the ``salt`` subdirectory will be used to complete the provisioning. 

``bundled`` - Area for placement of binary files required for installation / setup of a standalone server configuration only.  The USB and Vagrant provisioning will look for pre-downloaded files here and copy them if available.

.. _provisioning_structure:

Provisioning Structure
######################

Provisioning (up until the point where Salt takes over) is within the toplevel directory ``provision`` and 
is separated into ``usb``, ``vagrant``, ``kickstart`` and ``common`` subdirectories:

    - USB - is for building a USB device or image file (for a virtual machine boot)

    - Vagrant - is for further provisioning a pre-built VM image utilising ``Vagrant``

    - Kickstart - is for building a node using a network boot (``PXE`` booting)

    - Common - shared code used by all the provisioning methods

.. _saltstack_structure:

Saltstack Structure
###################

The salt layer is at this stage quite minimal and consists of areas for:

    - Configuration data (``pillar`` data). A hierarchy of data defined in several layers.

        + ``defaults`` - default values or fallbacks

        + ``layers`` - layers for different LANs, sites, roles, or hosts. NOTE, the SOE is extensible with it being a very simple matter to add extra layers.

        + ``demo`` - a demo / example configuration for a small lan with a single server and multiple workstations

    - Implementation states (``state`` files)

.. _states_structure:

The ``state`` area contains subdirectories related to:

    - ``build`` - Building custom RPM packages from data configured in the pillar area

    - ``accounts`` - Local system account creation (separate from IPA user account creation) 

    - ``cots`` - Installing COTS software (Draw-IO, eDraw, Pencil, StarUML)

    - ``network-init`` - Network configuration

    - ``deployments`` - Deploying services to individual nodes as specified in pillar:

        + Elasticsearch (baremetal or containerized)

        + Gitlab (baremetal)

        + Grafana (baremetal or containerized) 

        + IPA server or client

        + Kibana (baremetal or container) 

        + Prometheus (container)

        + Node Exporter (baremetal)

        + Nexus (container) 

        + Simple http services for network file access

        + PXE (+DHCP, TFTP) support for an infrastructure server 

    - ``_states`` - Custom Saltstack state modules

    - ``server`` - Configuration for servers only

    - ``workstation`` - Configuration for workstations

    - ``templates`` - Templates used by various states, primarily by Deployments

    - ``yum`` - Yum repository management

    - ``config`` - Deployment of configuration files 

    - ``util`` - utility states for administrative or developer use

