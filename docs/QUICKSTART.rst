.. _quickstart:

##########
QUICKSTART
##########

This document provides instructions for getting an environment set up
on your workstation, for trying out SoeStack and quickly seeing if it is 
suitable for your purposes.

These instructions may be specific for Fedora or other similar RedHat-flavoured distros such as CentOS and RHEL.

What we are going to do:

    - Install libvirt and vagrant

    - Configure a virtual network to match the ``demo`` configs provided

    - Run the vagrant deployment of the ``infra`` demo host

    - SSH into the node and have a look around

.. _quickstart_prep:

Preparation
===========

Vagrant
-------

Please see :ref:`vagrant_prep` for example initial configuration of ``libvirt`` / ``vagrant`` .

The ``infra`` machine defined in  the demo Vagrantfile (``provision/vagrant/Vagrantfile``) will run and configure a ``standalone`` machine and configure it to act as an infrastructure node for a demo SOE, with all required services running.

This ``standalone`` configuration is intended to be able to be built in a network environment without access to the internet. 

However to do that it requires a backup of a prepackaged Nexus installation, along with various RPM files downloaded first, to the RPM repo directories within the ``bundled/bootstrap-pkgs/<repo-name>/packages`` subdirectories.

.. _bundled_packages:

Bundled Packages 
----------------

Within ``bundled/bootstrap-pkgs`` there are various subdirectories for RPM files. Each subdirectory is accompanied by a ``<reponame>.listing.txt`` file and a ``<reponame>.url`` file. The ``url`` file contains the URL for the source packages. The ``listing.txt`` file contains a listing of which RPM files were used in testing.

Canned Nexus deployment
-----------------------

See :ref:`nexus_quickstart` for further info on an initial nexus setup.

.. _trying it out:

Trying it out
=============

Once you're all prepared:

.. code-block:: console 

    $> cd /path/to/soestack/
    $> cd provision/vagrant
    $> vagrant up
