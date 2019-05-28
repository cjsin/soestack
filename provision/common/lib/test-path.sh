#!/bin/bash
echo "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}/provision/common/lib/lib.sh"
echo "SS_DIR is now ${SS_DIR}"

