.. _about_soestack:

##############
About SoeStack
##############

SoeStack is a SOE designed to simplify the deployment of a Linux environment. 

It started as a 'playground' for me to try out different things with SaltStack, such as:

    - different ways of layering configuration data

    - writing custom SaltStack modules

    - possibilities for integrating SaltStack with IPA

It does not intend to be a SOE that does everything, but simply a base from which a SOE can quickly be built. To that end it supports initial building of an infrastructure server, followed by deployment of other node types by various methods (PXE, vagrant) with a demo configuration which can be customised or used as a basis for a new SOE, which can then further be extended.

It may not be entirely in a working state, I only work on the parts I'm interested in, in my free time and I may have break the older parts at any time. For example I've recently refactored the vagrant provisioning but may have broken the USB provisioning. Good luck, feel free to file a bug report or request help.

In its current state, it is primarily designed to support:

    - CentOS, RedHat, or Fedora based distros (tested only with CentOS, however should be quite compatible with RedHat and Fedora)

    - Deploying various services such as:

        - An IPA server for user / identity management

        - Gitlab (Community Edition)

        - A monitoring service and dashboard (Prometheus and Grafana)

        - An ElasticSearch stack (ElasticSearch, LogStash, and Kibana)

        - A small kubernetes cluster

        - A pull-through package repository for caching software from the internet

    - Configuring nodes, users, software selections etc within a SaltStack configuration area

    - Building nodes via USB, network (PXE) or virtual machines (via Vagrant).

    - Clamav antivirus

    - Schema checking for important configuration data

.. _about_getting_started:

Getting Started
###############

To just try it out and see what it does, please see :ref:`quickstart`.

Before you can use the files for your own purposes you will need to:

    - Determine your desired network configuration

    - Generate default root and grub passwords (see :ref:`modifying default passwords`)

    - Choose a name for your SOE, and a name for your local network (LAN)

    - Copy the 'demo' layer(s) within the pillar area and rename to use your new SOE name or LAN name

    - in various places, you will then need to change ``demo`` to your new SOE name or layer name, for example:

        + the variable ``ss.LAYERS``, which is by default set to ``soe:demo,site:testing,lan:example``

    - for example to use a SOE name ``example``, a site name ``testsite``, a lan name ``testlan``:
    
        + copy ``salt/pillar/soe/demo`` to ``salt/pillar/soe/example``

        + copy ``salt/pillar/layers/soe/demo.sls`` to ``salt/pillar/layers/soe/example.sls``

        + copy ``salt/pillar/layers/site/testing.sls`` to ``salt/pillar/layers/site/testsite.sls``

        + copy ``salt/pillar/layers/lan/example.sls`` to ``salt/pillar/layers/lan/testlan.sls``

        + copy ``salt/pillar/layers/lan/example/*`` to ``salt/pillar/layers/lan/testlan/*``

        + change ``ss.LAYERS`` to ``soe:example,site:testsite,lan:testlan``

    - In general, the layers defined with ss.LAYERS are used to select the salt configuration files used for any node

    - Customise various network settings, domain names, IP addresses, the GATEWAY, etc

    - Download various RPM packages required to 'bootstrap' an environment. The binary files required are not included in this SOE.

    - Either configure a Sonatype Nexus instance with various repositories to access files from the internet, and cache them, or else modify the nexus repos predefined within the SOE.

        + If you choose to use the predefined configuration, you will need to create 'registries' within your Nexus instance to match the configuration found within the salt pillar key ``nexus.repos`` and ``nexus.blobstores``.

        + Alternatively modify the pillar data to match your existing nexus repos

.. _about_deploying_with_usb:

Deploying an infrastructure server via USB
##########################################

Once you've modified all the configuration variables, you can generate a USB thumb drive that can be used to install a new server.

You will need to determine the Model name of the USB device and update various files within the ``provision/usb`` subfolder.

Make sure to specify the correct block device name so that you do not overwrite the wrong device.

The included ``ss-bundler`` tools require ``python3`` and the ``guestfs`` python modules, with the system configured with libvirtd support installed and enabled. The ``guestfs`` software is utilised for formatting a disk image or disk device and adding files to it.

Binary files will need to be added to the ``bundled`` subfolder, such as:

    - docker image files (primarily Sonatype Nexus OSS version)
    
    - various RPM files from different online repositories (centos, rpmfusion, epel, docker community edition)

    - (optional, if you will run nexus on this machine):

        + a Nexus ``blobs`` tarball and ``db-backup.tar``

        + if present, these will be used to bootstrap a new Nexus instance on the machine

The USB provisioning, if the ss.STANDALONE=1 flag is set, will set the server up as an infrastructure server which provides:

    - an IPA server

    - monitoring and a dashboard

    - a SaltStack master for controlling other nodes

    - a PXEboot service configured for building other nodes from this server, using SoeStack

    - a Kubernetes master deployment, to which other nodes can be added later

    - an ElasticSearch stack, for logging and log inspection

    - The ability to define package sets with lists of different packages to be installed on different node types.

    - IPA integration for SaltStack which is able to maintain DNS addresses configured within the SaltStack ``pillar`` data.

    - A print server (CUPS)

    - Various development tools:

        + python / pip

        + nodesource npm

    - A configured email service

    - Bash / profile settings

Where it may go
###############

Areas I'm interested in extending/improving it:

    - more work to automate provisioning and configuration of all services using SSL/https support with proper certificates from the IPA certificate authority

        + this isn't hard, as the IPA services provide a certificate authority which can generate certificates, the work just hasn't been done to automate this

        + would really like to do this and have all SOE services preconfigured to be deployed in a secure setup by default

    - I have heard anecdotally from organisations using it that the USB provisioning (using python guestfs support) is not usable within centos

        + this means even though the SOE is primarily for CentOS/RedHat environments, the USB provisioning currently requires a Fedora or other more modern setup to run successfully

        + it is possible that a CentOS/RedHat 8 install would provide new-enough libguestfs and python guestfs module support

    - (optionally) deploy the SOE services within a specified kubernetes cluster

        + this would be optional as it would require the administrator to have an understanding of kubernetes, and kubernetes-specific maintenance such as period renewal of cluster service account certs so that services do not stop working after a year.

        + it looks like it may actually be possible to deploy even the IPA server within a kubernetes cluster

        + if this can be done then providing the SOE services can be simply a matter of provisioning one infrastructure server running the kubernetes cluster and then adding resources to it as required / as they are available.

    - more testing with fedora clients (currently it's only tested with CentOS) to allow a more 'current' and less 'enterprise' environment, where that's suitable

    - more 'SOE' support work, in terms of having things autoconfigured or locked down according to SOE settings such as:

        - automatic email service autoconfiguration (partly done)

        - automatic browser settings (partly done)

        - enforced/locked-down screen saver settings (possible with gnome mandatory settings and KDE kiosk settings at least)

        - preconfigured desktop icons and browser bookmarks for your work environment

    - convert salt/IPA integration module to use IPA python modules directly instead of IPA commandline interface

    - looking at adding deployments for BitBucket, JIRA, and Confluence

        + support free versions for developers/testing but also support paid versions for organisations that have purchased licenses
    
    - Support CentOS/RedHat 8

        + CentOS / RedHat 8 introduces various issues such as:
        
            * making NetworkManager pretty much mandatory (no legacy network init script support at all)

            * python 2 / python 3 naming schemes have changed in a non-backwards-compatible way

            * primarily this affects network configuration in environments where NetworkManager causes issues, such as with docker and kubernetes, and ensuring a smooth installation of SaltStack without broken package dependencies

    - support SaltStack running on Python 3

        + currently the ``jinja`` templating within the canned SOE demo files requires the Python2 salt implementation

            * this should be a simple matter of changing all ``iteritems`` uses to ``items``

            * package selection is problemetic with RedHat / CentOS 8 due to how they've chosen to (re)name their python 3 and python 2 packages. 

                # saltstack packages for Python 3 currently require RPM package names that use the CentOS/RedHat 7 naming conventions

    - would like to provide a mapping between selected configurations and Australian Government ISM (Information Security Manual) controls.

    - using Nexus as a software repository mirror has some fair drawbacks, I would like to try to integrate Artifactory for an example as an alternative for organisations that can pay for a license.

