#!/bin/bsh

. /usr/local/bin/lib-ss.sh

secret_name_regex='^[A-Za-z]([-A-Za-z0-9_]*[A-Za-z0-9]|)$'

function check_dir()
{
    [[ -d "${1}" ]] || mkdir "${1}"
    chmod 700 "${1}"
}

function salt_secret_usage()
{
    msg "Usage: salt-secret [-h|-help|--help|help] [-master|-minion]  [-stdin|-env] [-save secret-name |-load secret-name |-list]"
}

function run()
{
    if (( verbose ))
    then 
        echo "Run: ${*}" 1>&2
    fi
    "${@}"
}


function do_load()
{
    local secret_name="${1}"
    local storage_file="${2}"
    local keyfile="${3}"
    local format="${4}"
    local output="${5}"
    local outfile="${6}"
    local -a flags=()
    
    local -a command=(openssl rsautl -decrypt -inkey "${keyfile}" -in "${storage_file}")
    if [[ "${format}" == "base64" ]]
    then
        if [[ "${output}" == "file" && -n "${outfile}" ]]
        then
            run "${command[@]}" | base64 > "${outfile}"
        else
            run "${command[@]}" | base64
        fi
    else 
        if [[ "${output}" == "file" && -n "${outfile}" ]]
        then
            run "${command[@]}" -out "${outfile}"
        else
            run "${command[@]}"
        fi
    fi
}

function do_save()
{
    local secret_name="${1}"
    local storage_file="${2}"
    local pubkey="${3}"
    local source="${4}"

    local input=""
    case "${source}" in 
        "")
            err "No data source specified!"
            salt_secret_usage
            return 1
            ;;
        stdin)
            msg "Reading from stdin"
            input=$(cat)
            local input_len=$(string_length "${input}")
            #msg "Read ${input_len} bytes of data"
            ;;
        env)
            local varname="${secret_name//-/_}"
            varname="${varname^^}"
            if env | grep -q "^${varname}="
            then 
                input="${!varname}"
                msg "Secret to save is ${input}"
            else
                err "Expected environment variable ${varname} was not set"
                salt_secret_usage
                return 1
            fi
            ;;
        *)
            salt_secret_usage
            return 1
            ;;
    esac

    local encrypted
    encrypted=$(run openssl rsautl -encrypt -inkey "${pubkey}" -pubin -out "${storage_file}" <<< "${input}")
    if [[ "$?" != "0" ]]
    then
        err "Encryption failed - data may be too long"
        return 1
    fi

    echo "Stored ${storage_file}"
    return 0
}

function salt_secret()
{
    local salt_pki="/etc/salt/pki"
    local storage="/etc/salt/secrets"
    local master_keyfile="/etc/salt/pki/master/master.pem" 
    local storage_dir=""
    local verbose=0
    local source=""
    local mode="auto"
    local automode=""
    local what="auto"
    local output="stdout"
    local format="binary"
    local outfile=""

    local arg
    while (( $# ))
    do
        arg="${1}"
        shift
        case "${arg}" in
            -h|-help|--help|help)
                salt_secret_usage
                return 0
                ;;
            -save|-store|--save|--store)
                mode="save"
                ;;
            -get|-load|--get|--load|-l)
                mode="load"
                ;;
            -ascii|-base64|--ascii|--base64)
                format="base64"
                automode+="load"
                ;;
            -outfile|--outfile|--out|-o)
                output="file"
                outfile="${1}"
                [[ -n "${outfile}" ]] || die "Output file was not specified"
                outfile=$(readlink -f "${outfile}")
                local outdir=$(dirname "${outfile}")
                [[ -d "${outdir}" ]] || die "Output directory ${outdir} does not exist"
                automode+="save"
                ;;
            -minion|--minion)
                what="minion"
                ;;
            -master|--master)
                what="master"
                ;;
            -stdin|--stdin)
                source="stdin"
                automode+="save"
                ;;
            -env|--env|-e)
                source="env"
                automode+="save"
                ;;
            -list|--list|-l)
                mode="list"
                ;;
            *)
                if [[ "${arg}" =~ ${secret_name_regex} ]]
                then
                    secret_name="${arg}"
                else
                    err "Invalid secret name: '${arg}'"
                    salt_secret_usage
                    return 1
                fi
                ;;
        esac
    done

    local automode_regex='^(save|load|auto|)$'
    if ! [[ "${automode}" =~ ${automode_regex} ]]
    then
        err "Conflicting flags specified - some are applicable only for load mode, and some for save mode."
        salt_secret_usage
        return 1
    elif [[ -z "${automode}" && "${mode}" == "auto" ]]
    then
        automode="load"
    fi

    if [[ "${mode}" == "list" ]]
    then
        msg "Available secrets:"
        ls /etc/salt/secrets/{minion,master}/* 2> /dev/null | sed 's%.*/%%' | sort | uniq
        return 0
    fi

    if [[ -n "${automode}" && "${mode}" != "auto" && "${automode}" != "${mode}" ]]
    then 
        err "A mode '-save' or '-load' was specified which conflicts with other flags that were present."
        salt_secret_usage
        return 1
    fi

    if [[ "${mode}" == "auto" ]]
    then
        mode="${automode}"
    fi

    if [[ -z "${mode}" ]]
    then
        salt_secret_usage
        return 1
    fi

    if [[ "${what}" == "auto" ]]
    then
        what="minion"
        [[ -f "${master_keyfile}" ]] && what="master"
    else
        [[ "${what}" == "master" && ! -f "${master_keyfile}" ]] && die "Master mode specified but this node has not run as a master"
    fi 
    
    local keyfile="${salt_pki}/${what}/${what}.pem"
    local pubkey="${salt_pki}/${what}/${what}.pub"
    local storage_dir="${storage}/${what}"

    [[ -n "${secret_name}" ]] || die "No secret name specified"
    [[ "${secret_name}" =~ / ]] && die "Invalid secret name specified"
    local storage_file="${storage_dir}/${secret_name}"

    check_dir "${storage}"
    check_dir "${storage_dir}"

    if [[ "${mode}" == "save" ]]
    then 
        do_save "${secret_name}" "${storage_file}" "${pubkey}" "${source}" 
    elif [[ "${mode}" == "load" ]]
    then
        do_load "${secret_name}" "${storage_file}" "${keyfile}" "${format}" "${output}" "${outfile}"
    fi
}

function generate_secrets_usage()
{
    local exitcode="${1:-0}"
    msg "${0##*/} [-h|-help|--help|help] [-random|-ask] [-single] [password-name] [password-name]..."
    msg ""
    msg "Options:"
    msg "  -random       - generate random passwords"
    msg "  -passphrase   - generate random passwords, and use a 'pw-' prefix on the secret name to identify it"
    msg "  -single       - use the same value for all passwords"
    msg "  -ask          - ask for the password value with an interactive prompt"
    msg "  -stdin        - read a single line from stdin as the password value. No verification of the value is performed"
    msg "  -min-length=x - specify a minimum length"
    msg "  -length=x     - specify a length for random generation"
    msg "  -allow-empty  - allow empty passwords (during entry, not generation)"

    return ${exitcode}
}

function run()
{
    if (( verbose ))
    then 
        echo "Run: ${*}" 1>&2
    fi
    "${@}"
}

function generate_secrets()
{
    local secret_names=()
    local style="ask"
    local multi=1
    local length=13
    local min_length=""
    local arg
    local prefix=""
    while (( $# ))
    do
        arg="${1}"
        shift
        case "${arg}" in
            -h|-help|--help|help)
                usage 
                return 0
                ;;
            -random)
                style="random"
                ;;
            -passphrase)
                style="passphrase"
                prefix="pw-"
                ;;
            -allow-empty)
                min_length=0
                ;;
            -min-length=*)
                min_length="${arg#-min-length=}"
                if ! [[ "${min_length}" =~ ^[0-9][0-9]$ ]]
                then
                    err "Invalid minimum length: '${min_length}'"
                    usage
                    return 1
                fi
                ;;
            -length=*)
                length="${arg#-length=}"
                if ! [[ "${length}" =~ ^[0-9][0-9]$ ]]
                then
                    err "Invalid length: '${length}'"
                    usage
                    return 1
                fi
                [[ -z "${min_length}" ]] && min_length="${length}"
                ;;
            -single)
                multi=0
                ;;
            -stdin)
                style="stdin"
                ;;
            -ask)
                style="ask"
                ;;
            *)
                if [[ "pw-${arg}" =~ ${secret_name_regex} ]]
                then
                    secret_names+=("pw-${arg}")
                else
                    err "Invalid secret name: '${arg}'"
                    usage
                    return 1
                fi
                ;;
        esac
    done

    local count=$(array_length "${secret_names[@]}")
    if ! (( count ))
    then
        err "No password names specified"
        usage
        return 1
    fi

    local pwvalue=""


    local secret_name
    for secret_name in "${secret_names[@]}"
    do 
        if [[ -z "${pwvalue}" ]]
        then 
            if [[ "${style}" == "ask" ]]
            then
                [[ -z "${min_length}" ]] && min_length="${length}"
                pwvalue=$(ask_password_twice "${secret_names[0]}" "${min_length}")
            elif [[ "${style}" == "random" || "${style}" == "password" || "${style}" == "passphrase" ]]
            then
                if [[ "${length}" -lt 3 ]]
                then 
                    pwvalue=$(mktemp -u XXXXXXX)
                    pwvalue="${pwvalue:0:${length}}"
                else
                    local template=$(printf "%0.sX" $(seq 1 ${length}))
                    pwvalue=$(mktemp -u $template)
                fi
            elif [[ "${style}" == "stdin" ]]
            then
                read pwvalue
                local pwlen=$(string_length "${pwvalue}")
                if [[ -n "${min_length}" && "${pwlen}" -lt "${min_length}" ]]
                then 
                    err "Password for ${secret_name} was rejected as too short. Minimum length is ${min_length}."
                    continue 
                fi
            fi
            
        fi
        
        run salt-secret "${secret_name}" -save -stdin <<< "${pwvalue}"

        if (( multi ))
        then
            pwvalue=""
        fi
    done
    return 0
}
