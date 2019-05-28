.. _about_soestack:

##############
About SoeStack
##############

SoeStack is a SOE designed to simplify the deployment of a Linux environment. 

It started as a 'playground' for me to try out different things with SaltStack, such as:

    - different ways of layering configuration data

    - writing custom SaltStack modules

    - possibilities for integrating SaltStack with IPA


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

.. _about_getting_started:

Getting Started
###############

To just try it out and see what it does, please see :ref:`quickstart`.

Before you can use the files for your own purposes you will need to:

    - Determine your desired network configuration

    - Generate default root and grub passwords

    - Choose a name for your SOE

    - Copy the 'demo' layer(s), and rename to use your new SOE name

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

Binary files will need to be added to the ``exclude`` subfolder, such as:

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

