#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function provision::salt::minion::validate-enrolment-tarball()
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

function provision::salt::minion::delete-key()
{
    if [[ -n "${SALT_MASTER}" ]]
    then  
        # This doesn't work with salt 2019.2 (tgt is an invalid keyword)
        #curl -sSk "https://${SALT_MASTER}:9009/run" -d client=wheel -d username=salt-enrol -d 'tgt=*' -d password=d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a -d eauth=pam -d fun=key.delete -d match="$(hostname -s)"
        : ;
        echo 'TODO - fix this!'
    else 
        msg "No salt master is configured."
    fi
}

function provision::salt::minion::auto-enrol()
{
    local mid="${1:-$(hostname -s)}"
    local useracct="${2:-salt-enrol}"
    local success=0
    # TODO - generate this
    echo "TODO: how is this still working?"
    local pw=d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a

    echo "Salt master is '${SALT_MASTER}'"
    provision::salt::minion::delete-key
    echo curl -sSk https://${SALT_MASTER}:9009/keys
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

    provision::salt::minion::validate-enrolment-tarball "${tarf}"
}
