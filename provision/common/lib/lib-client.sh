
function validate_enrolment_tarball()
{
    local tarf="${1}"
    if file "${tarf}" | egrep 'POSIX.tar' 
    then
        local tmpd=$(mktemp -t -d tmp_XXXXXXXXX)
        if cd "${tmpd}"
        then
            echo 
            tar xvf "${tarf}"
            touch minion.*
            if [[ ! -f minion.pub || ! -f minion.pem ]]
            then
                echo "The expected files did not exist"
            else 
                local f
                for f in minion.{pem,pub}
                do
                    if [[ ! -s "${f}" ]]
                    then
                        echo "File ${f} is zero-sized."
                        echo "This means the minion was already enroled."
                        echo "Removing this file."
                        rm -f "${f}"
                    echo
                    fi
                done
                if [[ -f minion.pub && -f minion.pem ]]
                then
                    success=1
                    mv -f minion.pub minion.pem /etc/salt/pki/minion/
                fi
            fi
        else
            echo "Could not create temp file"
        fi
    else 
        echo "The response was not a tar file (failure)."
    fi

    if (( success ))
    then
        echo 'Success!'
        return 0
    else
        echo "Failed"
        return 1
    fi
}

function salt_delete_key()
{
    if [[ -n "${SALT_MASTER}" ]]
    then  
        curl -sSk "https://${SALT_MASTER}:9009/run" -d client=wheel -d username=salt-enrol -d 'tgt=*' -d password=d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a -d eauth=pam -d fun=key.delete -d match="$(hostname -s)"
    else 
        echo "NO salt master is configured."
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
        echo "Curl command failed!" 1>&2
        return 1
    fi

    validate_enrolment_tarball "${tarf}"
}