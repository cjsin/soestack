#######################
USB Provisioning README
#######################

Initial setup for USB provisioning
##################################

Before the bundler will work, you'll need to do the following

ISOs
====

- First create a symlink 'isos' within this directory, to a directory
  which contains the ISO files.

- Edit the name of the ISO which is going to be used, within the bundler properties files.


VM image files
==============

- Create a symlink 'images' within this directory, to a directory which contains the libvirt image files


Output device
=============

If using usb:

    - Within bundler-usb.properties:

        + you must set the output device via the ``image`` setting (eg ``/dev/sdc`` or ``boot-image.raw``)

        + you can use an image file, but should also modify make sure the ``format`` is set to ``raw`` or ``qcow2``

        + you can use a block device, but should use the ``check-device <devicename> "<device model>"`` directive as an extra check

            * You must take responsibility yourself for choosing the correct output device and not overwriting your system disk!

    - Within the Makefile:
    
        + you must set IMAGE (for example boot-image.raw, or a block device such as ``sdc``)

        + you should set the bundler-usb.properties as the CONFIG in the Makefile


USB boot stick directory structure
##################################

The ``guestfs`` library is used (requires ``libvirt``) to perform the partitioning and copying of files into either a disk image or a real device such a USB thumb drive.

The structure is as follows:

    - All files from the ISO are copied onto the output device.

    - The ``isolinux`` from the ISO is copied as ``syslinux``.

    - ISO files are copied into an ``isos`` subdirectory.

    - A ``bundled`` directory is created, containing extra files which will be available during the installation

        + The SoeStack SOE itself is copied into ``bundled/soe``.

    - The ``provision`` folder is copied onto the output device as ``provision``.

Syslinux is used to make the device or image bootable.

Syslinux menu files are copied from /usr/share/linux into ``syslinux/`` on the output device.

The filesystem within the output device will be given a label such as ``SSBOOT`` and the syslinux boot entries will be updated to use this label to find the boot files.

The bundler-\*.properties configuration files provide the ability to perform various individual parts of the above setup, or perform a 'full' setup.

