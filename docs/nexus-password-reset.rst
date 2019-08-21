.. _nexus_password_reset:

##############################################
How to reset Sonatype Nexus OSS admin password
##############################################

These instructions are from the following Sonatype support pages. Please read them fully before continuing:

    - https://support.sonatype.com/hc/en-us/articles/115002930827-Accessing-the-OrientDB-Console

    - https://support.sonatype.com/hc/en-us/articles/213467158-How-to-reset-a-forgotten-admin-password-in-Nexus-3-x


In short:

    - systemctl stop ss-nexus-mirror

    - (check that it has stopped)

    - IMAGE=sonatype/nexus3:3.17.0   (replace with your version or docker image)

    - start docker container running a shell, with the nexus data mounted:
    
        .. code-block:: console
        
            $> docker run -it -p 8081:8081 -v /d/local/data/ss-nexus-mirror:/nexus-data $IMAGE /bin/bash

    - within the shell, you are going to start the nexus console 

        .. code-block:: console
        
            $ cd /opt/sonatype/nexus/
            $ java -jar lib/support/nexus-orient-console.jar 
    
    - within the nexus console, use the following two commands:

        .. code-block:: console 

            > connect plocal:../sonatype-work/nexus3/db/security admin admin

            > update user SET password="$shiro1$SHA-512$1024$NE+wqQq/TmjZMvfI7ENh/g==$V4yPw8T64UQ6GfJfxYq2hLsVrBY8D1v+bktfOxGdt4b/9BthpWPNUy/CBk6V9iA0nHpzYzJFWO8v/tZFtES8CA==" UPSERT WHERE id="admin"


Example session
###############

.. code-block:: console

    #> systemctl stop nexus

    #> IMAGE=sonatype/nexus3:3.13.0

    #> docker run -it -p 8081:8081 -v /d/local/nexus:/nexus-data $IMAGE /bin/bash
    bash-4.2$ cd /opt/sonatype/nexus/
    bash-4.2$ java -jar lib/support/nexus-orient-console.jar 

    OrientDB console v.2.2.36 (build d3beb772c02098ceaea89779a7afd4b7305d3788, branch 2.2.x) https://www.orientdb.com
    Type 'help' to display all the supported commands.
    orientdb> connect plocal:../sonatype-work/nexus3/db/security admin admin

    Connecting to database [plocal:../sonatype-work/nexus3/db/security] with user 'admin'...OK
    orientdb {db=security}> update user SET password="$shiro1$SHA-512$1024$NE+wqQq/TmjZMvfI7ENh/g==$V4yPw8T64UQ6GfJfxYq2hLsVrBY8D1v+bktfOxGdt4b/9BthpWPNUy/CBk6V9iA0nHpzYzJFWO8v/tZFtES8CA==" UPSERT WHERE id="admin"

    Updated record(s) '1' in 0.041000 sec(s).

    orientdb {db=security}> 

    orientdb {db=security}> exit

    bash-4.2$ exit
    exit

    #> systemctl start nexus
