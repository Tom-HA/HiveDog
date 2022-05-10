#!/usr/bin/env bash

main() {

    CI_PIPELINE_ID=${CI_PIPELINE_ID:-"LOCAL"}
    archive_name="starter"
    archive_pretty_name="Starter"
    archive_dir=starter

    check_root_and_exit
    check_and_install_makeself
    prepare_archive_dir
    build_archive
}

check_root_and_exit () {

    if [[ $EUID -ne 0 ]]; then
        echo "The script must run with root privileges."
        exit 1
    fi
}

check_and_install_makeself () {
    if command -v makeself &>/dev/null; then
        return 0
    fi
    echo "Makeself must be installed."
    if ! install_makeself; then
        echo "Could not install Makeself. Try install it manually. Exiting."
        exit 1
    fi
}

install_makeself () {
    echo "Updating repository lists"
    if ! apt-get update; then
        echo "Failed to update repository lists"
        exit 1
    fi

    echo "Installing makeself"
    if ! apt-get install makeself; then
        echo "Failed to install makeself"
        exit 1
    fi
}

prepare_archive_dir () {
    echo "Preparing archive directory"

    if ! [[ -d ${archive_dir} ]]; then
        mkdir ${archive_dir}
    fi

    files_paths=(
        "../src/starter.sh"
        "../src/hivedog.sh"
        "../config/hivedog.service"
    )

    for file_path in "${files_paths[@]}"; do
        if ! [[ -s ${file_path} ]]; then
            echo "Could not detect ${file_path}"
            exit 1
        fi
        
        if ! cp -fr ${file_path} ${archive_dir}; then
            echo "Could not copy ${file_path}"
            exit 1
        fi
    done
}

build_archive () {
    echo "Creating archive"

    makeself --needroot ${archive_dir} ${archive_name}.run "${archive_pretty_name}" bash ${archive_name}.sh

    ./${archive_name}.run --check || exit 1

    chmod +x ${archive_name}.run
}

main