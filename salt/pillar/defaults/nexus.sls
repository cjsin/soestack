
#firewall:
#    ports:
#        tcp:
#            8081-8083: ACCEPT

nexus:

    http_address:   nexus:8081
    docker_address: nexus:8082

    urls:
    # Example data
    #    centos:          http://nexus:7081/repository/centos
    #    dockerce:        http://nexus:7081/repository/dockerce
    #    docker:          nexus:7082

    blobstores:
    # Example data
    #    dockerhub:
    #    dockerce:
    #    fedora-dl:
 
    repos:
    # Example data
    # Example yum proxy
    #    centos:
    #        type:           proxy
    #        format:         yum
    #        blobstore:      centos
    #        remote_url:     http://mirror.centos.org/
    #        yum:
    #            centos:
    #                gpgkey_url:  http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7
    #                enabled:     1
    #                gpgcheck:    1
    #                gpgkey:      RPM-GPG-KEY-CentOS-7
    #                repos:
    #                    centos:
    #                        description: Centos $releasever - $basearch
    #                        path:        centos/$releasever/os/$basearch
    #
    #                    updates:
    #                        description: Centos $releasever - $basearch - Updates
    #                        path:        centos/$releasever/updates/$basearch
    #                    
    #                    # extras repo is needed for container-selinux
    #                    centos-extras:
    #                        description: Centos $releasever - $basearch - Extras
    #                        path:        centos/$releasever/extras/$basearch
    #
    #                    centos-plus:
    #                        description: Centos $releasever - $basearch - Plus
    #                        path:        centos/$releasever/centosplus/$basearch
    #                        enabled:     0

    # Example docker proxy
    #    dockerhub:
    #        type:           proxy
    #        format:         docker
    #        blobstore:      dockerhub
    #        remote_url:     https://registry-1.docker.io/
    #        docker:
    #            # Note this port is 8082 within the container, 7082 on the host
    #            http_connector: 8082
    #            docker_index:   'Use Docker Hub'
    #            enable_v1_api:  True

    # Example npm proxy
    #    npmjs:
    #        type:           proxy
    #        format:         npm
    #        remote_url:     https://registry.npmjs.org/
    #        blobstore:      npmjs

    # Example pypi proxy
    #    pypi:
    #        type:           proxy
    #        format:         pypi
    #        remote_url:     https://pypi.org/
    #        blobstore:      pypi

