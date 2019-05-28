FROM ss-centos-base:latest

# Podman does not correctly process .dockerignore 
# and also it has issues with the symlinks used within the provision/usb folder
# So just the provisioning subdirectories are added manually one at a time
ADD provision/common ${PROVISION_DIR}/common
ADD provision/kickstart ${PROVISION_DIR}/kickstart
ADD provision/docker   ${PROVISION_DIR}/docker

RUN ${PROVISION_DIR}/docker/provision.sh docker-quickstart.cfg \
    && ${clear_yum_cache}

RUN find /soestack/provision/|sort \
    && ${PROVISION_DIR}/common/provision.sh console \
    && ${clear_yum_cache}

#COPY salt ${SS_DIR}/salt
