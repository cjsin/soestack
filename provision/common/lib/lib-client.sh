#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function validate_enrolment_tarball()
{
    local tarf="${1}"
    if file "${tarf}" | egrep 'POSIX.tar' 
    then
        local tmpd=$(mktemp -t -d tmp_XXXXXXXXX)
        if cd "${tmpd}"
        then
            msg "" 
            tar xvf "${tarf}"
            touch minion.*
            if [[ ! -f minion.pub || ! -f minion.pem ]]
            then
                err "The expected files did not exist"
            else 
                local f
                for f in minion.{pem,pub}
                do
                    if [[ ! -s "${f}" ]]
                    then
                        err "File ${f} is zero-sized."
                        err "This means the minion was already enroled."
                        err "Removing this file."
                        rm -f "${f}"
                        msg ""
                    fi
                done
                if [[ -f minion.pub && -f minion.pem ]]
                then
                    success=1
                    mv -f minion.pub minion.pem /etc/salt/pki/minion/
                fi
            fi
        else
            err "Could not create temp file"
        fi
    else 
        err "The response was not a tar file (failure)."
    fi

    if (( success ))
    then
        msg 'Success!'
        return 0
    else
        err "Failed"
        return 1
    fi
}

function salt_delete_key()
{
    if [[ -n "${SALT_MASTER}" ]]
    then  
        # This doesn't work with salt 2019.2 (tgt is an invalid keyword)
        #curl -sSk "https://${SALT_MASTER}:9009/run" -d client=wheel -d username=salt-enrol -d 'tgt=*' -d password=d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a -d eauth=pam -d fun=key.delete -d match="$(hostname -s)"
    else 
        msg "No salt master is configured."
    fi
}

function salt_minion_autoenrol()
{
    local mid="${1:-$(hostname -s)}"
    local useracct="${2:-salt-enrol}"
    local success=0
    # TODO - generate this
    local pw=d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a

    salt_delete_key

    local tarf=/root/minion_enrol.tar
    if ! curl -sSk https://${SALT_MASTER}:9009/keys \
        -d mid="${mid}" \
        -d username="${useracct}" \
        -d password="${pw}" \
        -d eauth=pam \
        -o "${tarf}"
    then 
        err "Curl command failed!"
        return 1
    fi

    validate_enrolment_tarball "${tarf}"
}
