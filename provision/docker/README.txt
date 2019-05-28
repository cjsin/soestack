NOTE the docker provisioning is not the intended use for SoeStack,
but is simply used here for testing purposes.

Issues with docker deployment are:

    - docker containers generally have /etc/hosts and /etc/resolv.conf 
      newly created at each run (and at each stage during a docker image build)

    - docker containers will generally have a different hostname, mac address, IP address etc so are not generally suitable for the automated IPA enrolment

    - docker containers are generally intended to be used for a specific purpose

    - running systemd services within a container is problematic (when using docker)


Therefore the docker provisioning is just used to test:

    - generation of configuration vars (/etc/ss)
    
    - package installation / repo setup

    - compatibility of the above with a newer centos/redhat/fedora version

    - getting things to work both with centos, redhat, and fedora

    - troubleshooting changes brought in between major versions (eg networking support from RHEL7 to RHEL8)


Podman vs Docker
================

Pros/Cons of Podman
-------------------

    - (pro) seems to work very nicely as a standard user account 

    - (pro) apparently testing systemd stuff will work better

    - (con) podman appears to use the entire host file from the host, instead of generating a minimal one for each container

        + this means you can add host entries in your host file on the host, and have them available during the build, which allows for the build to obtain files from hostnames referenced in your host file.

    + (con) podman does not seem to add the containers own IP address to its host file

    + (con) podman (buildah) has issues processing ``.dockerignore`` files properly, even in the bleeding edge versions
    
        + this makes it very problematic to use with this project which contains subdiretories with large ISO files
        
    + (con) podman (buildah) fails checking cache beween build stages when a symlink points outside of the build area
    
        + this means it is not possible to put large files such as ISO files outside of the build tree

Pros/Cons of Docker
-------------------

    - /etc/resolv.conf written every time, between every build stage

    - /etc/hosts written every time, between every build stage

        + this makes it hard to use wget or curl for accessing large files from the host, or to access a locally hosted Nexus repo instead of standard centos repos

        + would require custom containers built for testing the project, and custom code written in the provisioning scripts, instead of being able to just using docker to simply test the existing provisioning scripts (with minimal changes)

    - starting services with systemctl within the container fails with DBus errors


Possible alternative for testing
--------------------------------

``docker compose`` should possibly be able to configure the etc/resolv.conf and/or /etc/hosts, or provide a preloaded dns service in such a way to make a container able to access the external services for testing the build process with fewer invasive changes

