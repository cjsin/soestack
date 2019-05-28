#!/bin/bash

echo "Primary provisioning - Vagrant-specific" 1>&2

. "${SS_DIR:-${BASH_SOURCE[0]%/provision/*}}"/provision/vagrant/lib/lib.sh

vagrant_provision "${@}"
