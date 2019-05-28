.. _vagrant_prep:

#############################
Libvirt / Vagrant Preparation
#############################

.. _installing_vm_tools:

Installing virtualisation tools
===============================

You will need libvirt and vagrant installed. We will also install the vagrant-libvirt integration.

.. code-block:: console 

    sudo yum -y install vagrant libvirtd virt-manager vagrant-libvirt

.. _libvirt_networking:

.. _vagrant_networking:

Configuring the virtual network for vagrant
===========================================

The demo files are designed to work with a subnet ``192.168.121.x/24``.

The following file can be used to configure libvirt to provide this network, if you do not already have it.

.. code-block:: xml 

    <network ipv6='yes'>
        <name>vagrant-libvirt</name>
        <forward mode='nat'/>
        <bridge stp='on' delay='0'/>
        <ip address='192.168.121.1' netmask='255.255.255.0'>
            <dhcp>
            <range start='192.168.121.1' end='192.168.121.254'/>
            </dhcp>
        </ip>
    </network>

Create this xml file somewhere then run:

.. code-block:: console

    $> virsh net-define /path/to/vagrant-libvirt-network.xml

Alternatively you can use an existing libvirt network, and search/replace 192.168.121 within the demo files.

.. _configuring_storage_pools

Configuring a storage pool
==========================

The included ``Vagrantfile`` expects ``libvirt`` to be configured with a storage pool (for disk image files) called ``linux``.

Either change this to match one of your existing storage pools in ``provision/vagrant/Vagrantfile``, comment it out, or create a new storage pool.

Example commands for creating a storage pool are as follows:

.. code-block:: console 

    dir=/var/lib/libvirt/images/vagrant

    mkdir -p "$dir"

    chown qemu.qemu "$dir"

    # If you do not use SELinux, you can skip the following chcon command
    chcon -t virt_content_t "$dir"

    virsh pool-create-as vagrant dir --target "$dir"

Configuring a user account to allow vagrant usage
=================================================

In Fedora, this is done by adding the user to the ``qemu`` group:

.. code-block:: console

    $> usermod -a -G qemu <username>

After adding the user to the group you may need to either log out entirely and then back in again, or else within an existing shell, use the following command to start a new shell with the new ``qemu`` group permissions activated:

.. code-block:: console 

    $> newgrp qemu

.. _installing_vagrant_images:

Configuring a Vagrant image file
================================

While vagrant itself can download ``box`` files, it is often (especially in a disconnected network environment) or when intending to re-use the files, preferable to download a box file separately and manually ``add`` it for use with vagrant. 

The demo ``Vagrantfile`` specifies an image file (``box`` file) named ``centos/7.1902.01``.

To have vagrant automatically download and install the image, replace ``centos/7.1902.01`` in ``provision/vagrant/Vagrantfile`` with ``centos/7``.

To manually download the image file and install it, you can browse to ``http://cloud.centos.org/centos/7/vagrant/x86_64/images/``, have a look at what image files are available, choose a version, then do as follows (this example uses the ``CentOS-7-x86_64-Vagrant-1902_01.Libvirt.box`` file and loads it with a name ``centos/7.1902.01``):

.. code-block:: console 

    $> wget http://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1902_01.Libvirt.box

    $> vagrant box add --name centos/7.1902.01 CentOS-7-x86_64-Vagrant-1902_01.Libvirt.box 

