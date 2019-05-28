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


Configuring a Nexus instance on your host
=========================================

First, get docker installed and running (no help here, look elsewhere, a standard install is fine).

Next, pull the sonatype image:

    - look at https://hub.docker.com/r/sonatype/nexus3/

    - find the latest sonatype nexus3 version (check the ``Tags`` tab).

    - for example the current version is 3.16.1, which is used in the following example commands.

    - run:

        .. code-block:: console

            docker pull sonatype/nexus3:3.16.1

    - create a data directory (as root):

        .. code-block:: console

            mkdir /data/nexus3
            chown 200.200 /data/nexus3
    
    - create a configuration file, ``/etc/sysconfig/nexus-mirror``, which will include the path to your data directory.

        .. code-block::

            ENV=
            # Edit the following line to include your timezone
            #TZ=--env TZ=<insert your timezone here>
            # NOTE this is configuring the Nexus container to forward traffic for 5 different ports,
            # which will correspond to different repositories that will be set up in it later.
            PORTS=-p 7081-7085:8081-8085
            # If you need to bind on a specific IP address, you can specify that like in the following example:
            #PORTS=-p IPADDRESS:7081-7085:8081-8085
            VOLUMES=-v /data/nexus3:/nexus-data
            DOCKER_OPTIONS=
            RM=
            ENTRYPOINT=--entrypoint /bin/bash
            # Put the correct nexus version below
            IMAGE=sonatype/nexus3:3.16.1
            OPTIONS=-c "/opt/sonatype/start-nexus-repository-manager.sh > /nexus-data/service.log 2>&1"


    - create a systemd service unit file ``/etc/systemd/system/nexus-mirror.service`` for the service:

        [Unit]
        Description=Sonatype Nexus OSS 3 Pull-through cache
        After=NetworkManager-wait-online.service network.target docker.service

        [Service]
        Environment=DOCKER_OPTIONS=
        Environment=PORTS=
        Environment=VOLUMES=
        Environment=ENTRYPOINT=
        Environment=IMAGE=
        Environment=OPTIONS=
        Environment=ENV=
        Environment=RM=--rm
        EnvironmentFile=-/etc/sysconfig/%p
        ExecStartPre=-/usr/bin/docker stop %p
        ExecStartPre=-/usr/bin/docker rm %p
        ExecStart=/usr/bin/docker run $(RM) --name %p  $TZ $DOCKER_OPTIONS $PORTS $VOLUMES -v /etc/localtime:/etc/localtime $ENTRYPOINT $IMAGE $OPTIONS
        ExecStop=/usr/bin/docker stop %p
        Type=simple
        User=root
        Group=root
        UMask=0007

        [Install]
        WantedBy=multi-user.target

    - if you use SELinux, make sure the data directory has the correct context to be accessed by a container:

        .. code-block:: console

            #> chcon -t container_file_t /data/nexus3

    - You may at this point need to add some firewall rules to allow access to the service. 

        + eg, use iptables, or firewalld, to allow access to ports 7081 through to 7085

    - If you already have existing nexus backup files (``db-backup.tar`` and ``blobs.tar``):

        + Unpack the backup data:

            .. code-block:: console 

                #> cd /data/nexus3
                #> mkdir -p restore-from-backup
                #> cd restore-from-backup
                #> tar xvf /path/to/db-backup.tar
                #> cd .. 
                #> tar xvf /path/to/blobs.tar

        + Configure the SELinux contexts, if you use SELinux (generally not needed if the directory was configured above):

            .. code-block:: console 

                #> cd /data/nexus3
                #> chcon -R -t container_file_t blobs restore-from-backup
        
        + Give the files appropriate ownership:


            .. code-block:: console 

                #> chown -R 200.200 /data/nexus3
        

    - Start the service

        .. code-block:: console 

            systemctl start nexus-mirror


    - Check the service

        .. code-block:: console 

            systemctl status nexus-mirror

    - If problems occurred:

        + check the log for this systemd service:

            .. code-block:: console 

                journalctl -u nexus-mirror 

        + check the log created when the service runs (configured in the ``sysconfig`` file):

            NOTE the service file configured above tells the container to put its log output to ``service.log`` within the configured data dir.

            .. code-block:: console 

                cat /data/nexus3/service.log

        + you're on your own from here

Checking it out
===============

Once you've started the service, if it seems to be running ok, use your web browser 
and try to access it at http://<your-hostname>:7081/

Unless you're using nexus backup files, the username and password for logging in will be the same as that for the released docker sonatype/nexus3 image.

Using your Nexus instance within SoeStack
=========================================

To utilise SoeStack with the ``demo`` configuration, you'll need to configure each ``repository`` in nexus that the demo configuration is expecting.

I would recommend reviewing the Sonatype Nexus documentation, and then configuring repos according to the settings within the ``salt/pillar/``, ``layers/soe/demo.sls`` file.

You will see in that file that it is expecting various 'blobstores' and 'repos' configured. The type of each repository, the associated internet URL, are within that file.

Configuring these repositories is left as an exercise for the reader, as Nexus automated provisioning was not (at the time of writing) capable enough to facillitate this being automated. Please see the Nexus documentation to configure each required repository.

Basic html caching repositories should be on port 8081. Docker registries to proxy various different sites should be configured on ports 8081 to 8085.

The systemd service above is mapping ports <8>08<x> to <7>08<x> because I had some other services running on the 808x range. So the SoeStack demo configurations utilise 708x instead of 808x. If you don't have the same limitation you can change that with a quick search/replace.


