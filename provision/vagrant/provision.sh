#!/bin/bash

echo "Primary provisioning - Vagrant-specific"

. /soestack/provision/vagrant/lib/lib.sh

vagrant_provision "${@}"
