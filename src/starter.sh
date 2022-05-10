#!/usr/bin/env bash

main() {
    log="/var/log/starter.log"
    completed_file_path="/var/log/starter_completed"
    version="0.0.1-local"

    if is_completed; then
        echo_log "Starter has already completed. Nothing to do..."
        exit 0
    fi

    update_repo_lists
    install_wd
    load_wd_module
    add_wd_module_permanently
    install_hivedog
    install_hivedog_service
    start_hivedog_service

    set_completed
    echo_green "Starter completed"

}

echo_log() {
    echo "[$(date '+%F %H:%M')] ${1}" |& tee -a $log
}


update_repo_lists() {
    send_to_spinner "apt-get update" "Updating repository lists"
}

install_wd() {
    send_to_spinner "apt-get install watchdog -y" "Installing watchdog package"
}


echo_red() {
  echo "${RED}""[$(date '+%F %H:%M')] ${1}""${RESET}" |& tee -a $log
}

echo_green() {
  echo "${GREEN}""[$(date '+%F %H:%M')] ${1}""${RESET}" |& tee -a $log
}

progress_spinner () {

    ## Loop until the PID of the last background process is not found
    while kill -0 "$BPID" &> /dev/null; do
        # Print text with a spinner
        printf "\r%s in progress...  ${YELLOW}[|]${RESET}" "$*"
        sleep 0.1
        printf "\r%s in progress...  ${YELLOW}[/]${RESET}" "$*"
        sleep 0.1
        printf "\r%s in progress...  ${YELLOW}[-]${RESET}" "$*"
        sleep 0.1
        printf "\r%s in progress...  ${YELLOW}[\\]${RESET}" "$*"
        sleep 0.1
        printf "\r%s in progress...  ${YELLOW}[|]${RESET}" "$*"
    done

    # Print a new line outside the loop so it will not interrupt with the it
    # and will not interrupt with the upcoming text of the script
    printf "\n\n"
}

send_to_spinner() {
    if [[ -z ${1} ]] || [[ -z ${2} ]]; then
        echo_red "Function 'send_to_spinner' didn't receive sufficient arguments"
        exit 1
    fi
    bash -c "${1}" &>> ${log} &
    BPID=$!
    progress_spinner "${2}"
    wait ${BPID}
    status=$?
    if [[ ${status} -ne 0 ]]; then
        echo_red "Failed to perform ${1}"
        exit 1
    fi
}

install_hivedog_service() {
    echo_log "Installting HiveDog service"

    if ! [[ -s ./hivedog.service ]]; then 
        echo_red "Internal error. Could not detect hivedog.service"
        exit 1
    fi

    if ! cp -f ./hivedog.service /etc/systemd/system/hivedog.service &>> ${log}; then
        echo_red "Failed to install HiveDog service"
        exit 1
    fi

}

is_completed() {
    if [[ -s ${completed_file_path} ]]; then
        retrun 0
    fi

    return 1
}

load_wd_module() {
    if lsmod |grep -q softdog; then
        return 0
    fi

    echo_log "Loading WatchDog module"
    if ! modprobe softdog; then
        echo_red "Failed to load 'softdog' module"
        exit 1
    fi
}

add_wd_module_permanently() {

    if grep -q "softdog" /etc/modules; then
        return 0
    fi

    echo_log "Configuring 'softdog' to load at boot"
    if ! echo "softdog" >> /etc/modules; then
        echo_red "Failed to add 'softdog' to /etc/modules"
        exit 1
    fi
}

install_hivedog() {

    if ! [[ -s ./hivedog.sh ]]; then
        echo_red "Internal error. Could not detect hivedog.sh"
        exit 1
    fi

    echo_log "Installting HiveDog"
    if ! cp -f ./hivedog.sh /usr/local/bin/hivedog; then
        echo_red "Failed to install HiveDog"
        exit 1
    fi

    if ! chmod 755 /usr/local/bin/hivedog; then
        echo_red "Failed to set permissions for HiveDog"
        exit 1
    fi

}

set_completed() {
    echo "${version}" > ${completed_file_path}
}

start_hivedog_service() {
    echo_log "Starting HiveDog service"
    if ! systemctl start hivedog &>> ${log}; then
        echo_red "Failed to start HiveDog service"
        exit 1
    fi

    echo_log "Enabling HiveDog service"
    if ! systemctl enable hivedog &>> ${log}; then
        echo_red "Failed to enable HiveDog service"
        exit 1
    fi
}

main