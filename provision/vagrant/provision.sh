#!/bin/bash

echo "Primary provisioning - Vagrant-specific" 1>&2

. /soestack/provision/vagrant/lib/lib.sh

vagrant_provision "${@}"
