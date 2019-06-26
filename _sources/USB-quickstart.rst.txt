.. _usb_quickstart:

##############
USB QUICKSTART
##############

This document provides instructions for performing the USB provisioning
(installing the SOE onto a USB key ready to build an infrastructure server)
and testing it using a virtual machine.

These instructions may be specific for Fedora, at this time the ``guestfs`` versions used to build the USB key are only known to work in Fedora (have not been tested on CentOS or RedHat).

What we are going to do:

    - Install python3 and python3 requirements

    - Configure systemd udev to grant group ownership for your user account, to USB storage devices with a specified vendor name (such as "SanDisk")
    
    - Configure a virtual network to match the ``demo`` configs provided

    - Generate an installer filesystem onto a USB drive
    
    - Create a virtual machine to test using the USB drive to install onto a virtual machine disk image

.. _usb_quickstart_prep:

Preparation
===========

Python3
-------

Install python3:

    .. code-block:: console
    
        $> sudo yum install python3

Install python3 guestfs:

    .. code-block:: console
    
        $> sudo yum install python3-libguestfs

Install python3 attrdict package:

    .. code-block:: console
    
        $> sudo pip install attrdict

Other requirements
------------------

Certain files are needed which will be copied onto the USB image to make it bootable.

You'll need a few extra packages installed, such as ``syslinux`` and ``syslinux-extlinux``:

    .. code-block:: console

        $> sudo yum install syslinux syslinux-extlinux


Libvirt configuration for user access
-------------------------------------

It is assumed you have configured libvirt on your system to allow a user account to run virtual machines. This will allow the user account to use the guestfs libraries to modify disk images (or devices). In my personal opinion this is safer than running the tools as root, because then you are able to run the tools with block device access granted to only specified disks. Whereas if you need to run the tools as root then they will have access to overwrite any of your system disks.

You can use the ``libvirt`` or ``qemu`` documentation to configure those to allow your user account access. In my system, I believe all that was required was to add my user account to the ``qemu`` group (and potentially log out / in, or use ``newgrp qemu``).

Libvirt network configuration
-----------------------------

Please see :ref:`vagrant_networking` to configure a libvirt network with appropriate network configuration for the demo USB configs.

Systemd udev configuration
--------------------------

To allow a user ``example`` to write to USB drives with manufacturer ``SanDisk``, you can:

    - create a file such as /etc/udev/rules.d/99-usb-storage-group.rules:

        .. code-block:: console

            ENV{MAJOR}=="8", SUBSYSTEM=="block", ACTION=="add", ENV{ID_USB_DRIVER}=="usb-storage", ENV{ID_VENDOR}=="SanDisk", GROUP="example"

    - This will modify the group ownership of SanDisk USB storage devices, to be owned by group ``example``, when they are inserted (any stick that is already connected will need to be reinserted).

    - Additionally, the device ownership may be changed after using it with libvirt to test using a virtual machine, so the stick may need to be reinserted to restore the ownership after performing such a test.

Choosing a network configuration
--------------------------------

Especially if you want the installed system to have access to the internet (for example to download missing packages),
you'll need to either select a network configuration (lan layer) that gives access to the internet, or create your own.

If you are using a virtual machine, with a libvirt network as configured above, you can select the predefined ``qemu`` lan, by setting ``lan:qemu`` within the value for ``ss.LAYERS``.



Updating the demo configs to use your USB stick
-----------------------------------------------

The example configuration provided here assumes you have a stable disk environment, where device names to not change much.

For the purposes of this example, the USB stick is assumed to be detected as /dev/sdc each and every time. However device names can change, so you should be very careful to use the correct device name for your USB stick and keep it up to date, so that you do not overwrite a system disk. This is especially important if you are running the provisioning as the ``root`` user. Preferably, you should run it as a regular user account, and should **only** allow access to the block device for your single USB key/stick, using something such as the udev rules shown in the example above.

As outlined in the LICENSE, no responsibility is taken by the author for any damage caused by this software. You must take responsibility yourself for the potential that it could overwrite the wrong device.

For this example we are going to do two things:

    - Determine the "Model" of the USB stick 

    - Determine the linux block device for the USB stick 

    - Update the ``bundler-usb.properties`` file

    - Update the ``Makefile``

Determine the USB device model:

    - the simplest way to do this is use ``lsusb -v`` and search for the USB device vendor (``idVendor``) and product (``idProduct``):

        .. code-block:: console

            #> lsusb -v

        or, to look for a 'SanDisk' device:

        .. code-block:: console

            #> lsusb -v 2> /dev/null  | egrep 'idVendor|iProduct|Serial' | egrep -A2 SanDisk

    - alternatively you can run, as root, ``udevadm monitor --property`` and then insert the drive, and look at the generated output.

        .. code-block:: console

            #> udevadm monitor --property | egrep 'SERIAL|MODEL'

Determine the USB block device:

    - It is assumed you are competent enough with Linux systems to determine this yourself, at your own risk. I would simply use the ``lsblk`` or ``blkid`` tools. The USB device model can be used to perform a sanity check on the specified device, using the ``check-device`` directive in the bundler properties file, however **you should not rely on this** - it is a simple check only and may not be reliable - **you should check that the device is correct each and every time before running the tool(s)!**

Updating ``bundler-usb.properties``:

    - Look at ``bundler-usb.properties`` and find the lines containing the directives ``image`` and ``check-device``. Example lines for a system with the USB stick attached as ``/dev/sdc``, with a device ``Model`` of ``USB Device Model`` are shown here:

        .. code-block:: console
        
            image         /dev/sdc
            check-device  sdc "USB Device Model"

    - Modify the ``image`` and ``check-device``, updating the device name (``sdc``) and USB device model (``"USB Device Model"``) as appropriate for the values you have determined above. 

        * You must take responsibility yourself for choosing the correct output device and not overwriting your system disks!

Updating the Makefile:

    - Modify the ``CONFIG =`` line, to specify ``bundler-usb.properties`` 

    - Modify the ``IMAGE =`` line, to specify the USB block device that you determined above (for example, ``/dev/sdc``).

        * You must take responsibility yourself for choosing the correct output device and not overwriting your system disks!

.. _usb_bundled_packages:

Bundled Packages 
----------------

Within ``bundled/bootstrap-pkgs`` there are various subdirectories for RPM files. Each subdirectory is accompanied by a ``<reponame>.listing.txt`` file and a ``<reponame>.url`` file. The ``url`` file contains the URL for the source packages. The ``listing.txt`` file contains a listing of which RPM files were used in testing.

Generally you will need to download these packages into each ``packages`` subdirectory, and then run ``createrepo``.

For example, with the ``dockerce`` repo:

    - Determine the URL(s) of the source files (stored within ``bundled/bootstrap-pkgs/dockerce.url``)\

    - Download the RPM files into ``bundled/bootstrap-pkgs/dockerce/packages``

        .. code-block:: console

            $> cd /path/to/soestack/bundled/boostrap-pkgs/dockerce/packages
            ## (download the files here)

    - Run ``createrepo`` within the ``dockerce`` directory

        .. code-block:: console

            $> cd /path/to/soestack/bundled/boostrap-pkgs/dockerce
            $> createrepo . 

Canned Nexus deployment
-----------------------

See :ref:`nexus_quickstart` for further info on an initial nexus setup. 

To build the demo standalone infrastructure server, you'll need a nexus ``blobs.tar`` and ``db-backup.tar``,
which will be stored within ``bundled/nexus``.

Root passwords
--------------

If you are using this for a real deployment, not just testing it out, you will want to update the default root passwords and grub passwords. See :ref:`modifying default passwords` for more information.

.. _trying out usb:

Trying it out
=============

Once you're all prepared, and sure you have specified all the right devices and won't be overwriting any system disk:

    .. code-block:: console 

        $> cd /path/to/soestack/
        $> cd provision/usb
        $> make full

If this works, you can later update the stick with various subsets of the full update, using such as ``make update`` and ``make kickstarts``.

Example output is shown below:

    .. code-block:: console 

        $> cd /path/to/soestack/
        $> cd provision/usb
        $> make kickstarts
        ./ss-bundler.py bundler-usb.properties  --mode  kickstarts
        Preprocess LOAD: ['bundler-dev.properties', 'ignoring', 'verbose', 'image', 'format', 'dry_run']
        Ignoring VERBOSE directive while processing bundler-dev.properties as instructed
        Ignoring IMAGE directive while processing bundler-dev.properties as instructed
        Ignoring FORMAT directive while processing bundler-dev.properties as instructed
        !!Default mode found - full
        !!Mode KICKSTARTS accepted
        !!Default mode found - full
        !!Mode KICKSTARTS accepted
        !!Processing 131 accepted lines
        * CHECK_DEVICE sdc Example
        Device sdc has the expected model: 'Example'
        * IMAGE /dev/sdc
        * FORMAT raw
        * VERBOSE 1
        * STRICT 1
        * DRY_RUN 0
        @@ Available modes:
        @@ Full - Build a new image (overwriting) and copy all files (including bundled files)
        @@ Create - Build a new image (overwriting) and copy all files required for installation
        @@ (excludes large bundled data)
        @@ Update - Update an already-built image, update boot files
        @@ (excludes large bundled data)
        @@ Quick - Update kickstarts, provisioning, boot label etc
        @@ (excludes ISO, non-critical ISO content, and large bundled data)
        @@ Bundle - Update the large data bundles (nexus repository backup, gitlab backup, etc)
        @@ Isos - Copy the isos on as files
        @@ 
        @@ Example session:
        @@ 
        @@ Getting started:
        @@ 
        @@ ss-bundler --mode=create
        @@ (you may then test that the USB stick works to build the server)
        @@ 
        @@ When it is working fine, or after your backups have run, you might
        @@ update with the backup data
        @@ ss-bundler --mode=bundle
        @@ 
        @@ NOTE:
        @@ 
        @@ The way this works, is lines are processed from the top down,
        @@ reading an ACTION from each line -- however with a line being
        @@ ignored if in a section that specifies it is ONLY for a mode
        @@ that does not match the current selected mode (--mode commandline option).
        @@ After reaching the end of the file, the BUILDER command is invoked with a
        @@ set of arguments that have been built up by the actions that were processed
        @@ above.
        @@ 
        @@ Use the DRY_RUN 1 action to view the command without execution.
        @@ 
        @@ Good luck.
        * BUILDER ./build-boot-image.py
        * ISO ../../bundled/iso/CentOS-7-x86_64-DVD-1810.iso
        * LABEL SSBOOT
        * VAR cmdline
        * APPEND cmdline  
        * APPEND cmdline inst.kexec inst.kdump_addon=off
        * APPEND cmdline inst.ks=hd:LABEL=SSBOOT:/ks.cfg
        * EDIT syslinux/syslinux.cfg
        #==============================================
        # Quick update mode (kickstarts, soestack provisioning)
        #==============================================
        * BUILD --verbose modify --ext4 --overwrite --clear
        #==============================================
        # Copy kickstarts
        #==============================================
        * TOPDIR /
        * COPY entire dir ../ as provision
        * COPY single file ../kickstart/kickstart.cfg as ks.cfg
        * APPEND cmdline net.ifnames=0
        * APPEND cmdline biosdevname=0
        * APPEND cmdline ss.ROOT_PW=$1$NxR2J0fM$QS2U2lrQxpDAlb9JPWB2v/
        * APPEND cmdline ss.STANDALONE=1
        * APPEND cmdline ss.ADD_HOST=192.168.121.1,gateway
        * APPEND cmdline ss.ADD_HOST=192.168.121.101,infra.demo.com,infra,master,salt,ipa
        * APPEND cmdline ss.ADD_HOST=192.168.121.103,nexus.demo.com,nexus
        * APPEND cmdline ss.NAMESERVER=192.168.121.1
        * APPEND cmdline ss.NETDEV=eth0
        * APPEND cmdline ss.GATEWAY=192.168.121.1
        * APPEND cmdline ss.IPADDR=192.168.121.101
        * APPEND cmdline ss.IPADDRS=192.168.121.101/24,192.168.121.103/24
        * APPEND cmdline ss.IPPREFIX=24
        * APPEND cmdline ss.TIMEZONE=UTC
        * APPEND cmdline ss.BUNDLED_SRC=/e/bundled
        * APPEND cmdline ss.DEVELOPMENT=1 ss.INTERACTIVE=0 ss.WAIT=0 ss.INSPECT=0 ss.VERBOSE=1
        * APPEND cmdline ss.DOMAIN=demo.com
        * APPEND cmdline ss.LAYERS=soe:demo,site:testing,lan:qemu,private:example
        * APPEND cmdline ss.NEXUS=nexus.demo.com:7081
        * APPEND cmdline ss.ROLES=all-in-one-sde-server-node
        * APPEND cmdline ss.SALT_MASTER=infra.demo.com
        * APPEND cmdline ss.SALT_TYPE=master
        * APPEND cmdline ss.SKIP_CONFIRMATION=0
        * APPEND cmdline ss.HOSTNAME=infra.demo.com
        * APPEND cmdline rd.shell noquiet
        127 actions of 127
        ./build-boot-image.py 
            --iso ../../bundled/iso/CentOS-7-x86_64-DVD-1810.iso 
            --img /dev/sdc 
            --imgformat raw 
            --verbose 
            modify --ext4 --overwrite 
                    --clear 
                    --label SSBOOT 
                    --editdef syslinux/syslinux.cfg 
                    --copydef --dstdir / 
                        --copydir ../ --dstname provision 
                        --copy ../kickstart/kickstart.cfg --dstname ks.cfg 
        Creating 5 extra actions.
        UPDATE
            Prepare for Update
                Startup guestfs
                OK
                Access images
                    Checking image file /dev/sdc against imgformat raw
                OK
                Determine partitioning
                    Found (Guestfs) USB/image partition /dev/sdb1
                OK
                Mount
                    Create mountpoint /usb
                    OK
                    Mount /usb
                    OK
                    Create mountpoint /iso
                    OK
                    Mount /iso
                    OK
                OK
            OK
            Mount
            OK
        OK
        Running 3 extra actions:
        - UpdateLabelAction
        - CopyDirAction
        - CopyAction
        .
        Update label
            Update image filesystem label
            OK
        OK
        Spawning tar : ['tar', 'cf', '-', '--checkpoint=10000', '-C', '../', '.']
        Waiting for tar process to finish
        OK
        Copying files from iso to ks.cfg - ['../kickstart/kickstart.cfg']
            Upload ../kickstart/kickstart.cfg to /usb/ks.cfg
                Overwriting /usb/ks.cfg
            OK
        OK
        Cleanup
            Umount /usb
            OK
            Umount /iso
            OK
        OK
        Done.

Testing the USB using libvirt
=============================

If you don't have physical hardware to test the USB device, you can use a virtual machine to test it.

An example libvirt domain file is shown, and some commands for creating a test disk image file.


Creating a system disk image:

    .. code-block:: console

        #> qemu-img create  -f qcow2 /var/lib/libvirt/images/test-soestack-system-disk.qcow2 80G


Creating a virtual machine domain:

    - Generate a new ``UUID``:

        .. code-block:: console 

            $> uuidgen 
            26bf3871-a1c6-4b35-9505-dad194dc6715

    - Create a virtual machine

        + Use the ``virt-manager`` GUI to create the virtual machine.

            - Add the disk image /var/lib/libvirt/images/test-soestack-system-disk.qcow2 as a disk device
            
            - Add your USB block device, as a disk devices

            - Choose ``customise the configuration before booting``.
            
            - Enable the boot menu

            - Select the virtual disk device associated with the real USB device, as the boot device

            - Start the virtual machine

