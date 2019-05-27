.. _nexus_quickstart:

################
Nexus quickstart
################

The Nexus repository is utilised within the SOE to avoid the same packages being downloaded again every time.

Nexus is a package mirror which can act as a pull-through cache.

This document will not describe how to run and configure Nexus, but simply how it needs to be utilised within the demo SOE. 

You'll need to configure a Sonatype ``Nexus`` instance with multiple ``repository`` instances, with properties as defined within ``salt/pillar/layers/demo.sls``.

To do that, configure Sonatype Nexus as per their documentation, then add instances of ``blobstore`` and ``repository``, using the types and remote URLs shown within ``salt/pillar/layers/demo.sls``.

After that is done, you can:

    - use the ``Tasks`` within Nexus to create a backup of its databases to its ``backups`` folder

    - create a ``db-backup.tar`` archive file, containing the database backup files

    - create a ``blobs.tar`` archive file, containing the ``blobs`` subdirectory from the nexus installation

    - store ``db-backup.tar`` and ``blobs.tar`` within ``bundled/nexus/``.

