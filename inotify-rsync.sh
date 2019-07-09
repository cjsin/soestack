#!/bin/bash

DEBUG=""
SCRIPT_DIR=""
SCRIPT_NAME=""
PARENT_PID="$$"
PROG="${0##*/}"
HELP_REGEX='(^|[[:space:]])(-h|-help|--help|help)([[:space:]]|$)'
PERIOD=5
DELAY=1.5
WATCH=("salt" "${BASH_SOURCE[0]}")
EVENTS=(
    -e modify
    -e attrib
    -e close_write
    -e move
    -e move_self
    -e create
    -e delete
    -e delete_self
)

RSYNC=(
    -a 
    --delete 
    --info=all0,skip1,remove1,name1,copy1,stats1,misc0,progress0,symsafe1,mount1,flist0
)
RSYNC_SRC="./salt/"
RSYNC_DST="/soestack/salt/"
SERVER=""

function usage()
{
    local exit_status="${1:-0}"
    msg "Usage: ${PROG} server-ip"
    msg ""
    msg "Will sync the salt directory to the server either periodically"
    msg "or when the salt files change (if you have inotifywait installed)"
    exit "${exit_status}"
}

function msg()
{
    echo "${*}" 1>&2
}

function err()
{
    msg "ERROR: ${*}"
}

function warn()
{
    msg "WARNING: ${*}"
}

function die()
{
    msg "Fatal: ${*}"
    cleanup
    exit 1
}

function enter_script_dir()
{
    local bs0="${BASH_SOURCE[0]}"
    if [[ "${bs0:0:1}" == "/" ]]
    then
        SCRIPT_DIR="${bs0%/*}"
        cd "${bs0}"
        return $?
    elif [[ "${bs0:0:2}" == "./" ]]
    then
        SCRIPT_DIR="${PWD}"
        return 0
    else
        SCRIPT_NAME="${bs0##*/}"
        SCRIPT_DIR=$(dirname "$(readlink -f "${bs0}")")
        if [[ -f "${SCRIPT_DIR}/${script_name}" ]]
        then
            cd "${SCRIPT_DIR}"
            return ?
        fi
        SCRIPT_NAME="${bs0##*/}"
        SCRIPT_DIR=$(dirname "$(readlink -f "${}")")
        if [[ -f "${SCRIPT_DIR}/${script_name}" ]]
        then
            cd "${SCRIPT_DIR}"
            return ?
        fi
        return 1
    fi
}

function generate_events()
{
    msg "From ${PWD}, watching ${WATCH[*]} for changes..."
    run "${@}" inotifywait -m -r --format '%T %e %w' --timefmt "%s" "${EVENTS[@]}" "${WATCH[@]}" | stdbuf -i0 -o0 -e0 uniq 
    msg "${FUNCNAME[0]} status ${?}"
}

function unbuffered()
{
    stdbuf -i0 -o0 -e0 "${@}"
}

function indent()
{
    stdbuf -i0 -o0 -e0 sed 's/^/  /'
}


function perform_sync()
{
    ${DEBUG} run rsync "${RSYNC[@]}" "${RSYNC_SRC}" "root@${SERVER}:${RSYNC_DST}" 2>&1 | indent 
}

function run()
{
    msg "DATE: $(date)"
    if [[ -n "${DEBUG}" ]]
    then
        msg "RUN : ${*}"
        ${DEBUG} "${@}" < /dev/null
    else
        msg "RUN : ${1}"
        "${@}" < /dev/null
    fi
}

function timestamp()
{
    date "${@}" "+%H:%M:%S"
}

function handle_events()
{
    local now=$(date +%s)
    local execute_routine="${1}"
    local when what where when_and_where
    local last
    local needs_sync

    ## NOTE: initialisation event is no longer required since
    # we select only specific events.
    # Note the initialisation event is read and discarded
    #msg "Waiting for initialisation event..."
    #read when_and_where
    #read when what where <<< "${when_and_where}"
    #msg "Discard initialisation event at time $(timestamp -d "@${when}")"

    local last_line=""
    while read when_and_where
    do 
        [[ "${when_and_where}" == "${last_line}" ]] && continue
        read when what where <<< "${when_and_where}"

        if [[ -z "${where##*/}" && "${what}" == "ATTRIB" ]]
        then
            msg "  Discard directory-only attribute event at $(timestamp -d "@${when}") (${when})"
            continue
        fi

        msg "  When : $(timestamp -d "@${when}") (${when})"
        msg "  Where: ${where}"
        msg "  What : ${what}"

        if [[ "${when}" -gt "${last_sync}" ]]
        then
            needs_sync="${when}"
            msg "  Will sync in ${DELAY} seconds"
            msg ""
        else

            msg "  Skip event $(timestamp -d "@${when}") during sleep before last sync"
            continue
        fi

        if (( needs_sync ))
        then
            # Sleep at least 1 second before syncing 
            # so that the files have time to save
            sleep "${DELAY}"
            msg "########"
            msg "#Changes at $(timestamp -d "@${when}") have initiated a sync at time $(timestamp)"
            msg "########"
            # Record the fact that we need to sync 
            "${execute_routine}"
            msg "  Completed sync."
            msg ""
            last_sync="${needs_sync}"
            needs_sync=0
            msg "Waiting for further events."
        else
            msg "No sync needed!"
        fi
    done
}

function watch_for_changes()
{
    generate_events | handle_events perform_sync
}

function cleanup()
{
    local status="${1:-0}"
    local why="${2:-1}"
    msg ""
    msg "${why}"
    # Kill all children of this process
    pkill -P $$
    exit ${status}
}

function interrupted()
{
    cleanup 0 "Interrupted."
}

function terminated()
{
    cleanup 1 "ERROR: Terminated"
}

function sleep_loop()
{
    local execute_routine="${1}"
    while (( 1 ))
    do
        run "${execute_routine}"
        sleep "${PERIOD}"
    done
}

function main()
{
    if [[ "${*}" =~ ${HELP_REGEX} ]]
    then
        usage 0
    elif [[ "${#}" != 1 ]]
    then
        usage 1
		else
        SERVER="${1}"
        shift
    fi

    if ! enter_script_dir
    then
        die "Could not determine script dir!"
    fi

    method="watch"

    if ! command -v inotifywait 2> /dev/null > /dev/null
    then
        warn "inotifywatch tool is not installed."
        warn "Falling back to sleep loop"
        method="sleep"
    fi

    trap "interrupted" "INT"
    trap "terminated" "TERM"

    case "${method}" in
        watch)
            watch_for_changes perform_sync < /dev/null &
            sleep 2
            msg "Watching for changes..."
            ;;
        sleep)
            sleep_loop perform_sync < /dev/null &
            sleep 2
            msg "Syncing every ${PERIOD} seconds"
            ;;
        *)
            die "Unrecognised method: ${method}"
            ;;
    esac 

    sleep 1

    msg "Completed startup..."
    
    user_input_loop < /dev/stdin &

    wait
    
    cleanup

    echo "${PROG}: Exiting" 1>&2
}

function user_input_loop()
{
    trap "kill -INT ${PARENT_PID}" INT
    local line
    while (( 1 ))
    do
        msg "Hit Ctrl-C to exit, or Enter to initiate an immediate sync."

        read line

        msg "NOTICE: User initiated sync by hitting return."
        perform_sync
        msg "Going back to normal operation. "
    done 
}

main "${@}"
