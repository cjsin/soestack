#!/bin/bash

# Nothing to add here, but still need to load this library for the caller
[[ -n "${SS_LOADED_KS_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/kickstart/lib/lib.sh
