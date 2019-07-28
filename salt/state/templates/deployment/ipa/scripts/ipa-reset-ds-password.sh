#!/bin/bash

. /usr/local/bin/lib-ss.sh || exit 1
. /usr/local/bin/lib-ipa.sh || die "Failed loading ipa lib"

ask_password_twice "new Directory Manager Password" 8
