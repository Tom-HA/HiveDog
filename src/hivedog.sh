#!/usr/bin/env bash

main() {
    api_endpoint="api.hiveos.farm/worker/api"
    body='{"method":"stats", "params": {"rig_id":"-1", "passwd": "1"}}'
    log="/var/log/hivedog.log"

    start_hivedog_checks
}

is_connected() {
    # This is a similar check to the one in 'net-test' utility in HiveOS

    response="$(curl --silent --max-time 15 -H 'Content-Type: application/json' -X POST -d \'${body}\' ${api_endpoint})"

    if [[ -z $(jq -c "if .error.code then . else empty end" 2> /dev/null <<< $response) ]]; then
        return 1
    fi

    retrun 0
}

echo_log() {
    echo "[$(date '+%F %H:%M')] ${1}" |& tee -a $log
}

start_hivedog_checks() {
    counter=0
    while true; do
        if [[ ${counter} -ge 6 ]]; then
            # The infinite loop in this condition will cause the watchdog to reset the system 
            continue
        fi 

        if ! [[ -c /dev/watchdog ]]; then
            echo_log "Could not detect watchdog device"
            continue
        fi

        echo > /dev/watchdog

        if ! is_connected; then
            sleep 10
        fi

        (( counter++ ))
}


main