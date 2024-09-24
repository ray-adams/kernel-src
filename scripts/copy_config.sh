#!/bin/sh

# Script Name: copy_config.sh
# File Path: <git_root>/scripts/copy_config.sh
# Description: Copy kernel configuration based on user selected version.

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.8.3

# Obtain the path for <git_root>
working_dir="$(git rev-parse --show-toplevel)"
src_path="/usr/local/src/"

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Make sure the user doesn't run this script as root.
if [ "$(id -u)" -eq 0 ]; then
    echo "${red}Please do not run this script as root.${nc}"
    exit 1
fi

select_version() {
    echo "${green}Available Linux kernels:${nc}"
    ls "${src_path}/${system}/linux/"
    while true; do
        echo "${green}Select a version:${nc}"
        read version
        if [ -d "${src_path}/${system}/linux/${version}" ]; then
            linux_src_path="${src_path}/${system}/linux/${version}/"
            break
        elif [ -d "${src_path}/${system}/linux/linux-${version}/" ]; then
            linux_src_path="${src_path}/${system}/linux/linux-${version}/"
            break
        else
            echo "${red}Please choose a valid version.${nc}"
        fi
    done

    local_version="$(awk '/# Linux\/x86/ {print $3}' "${linux_src_path}/.config")-$(grep "^CONFIG_LOCALVERSION" "${linux_src_path}/.config" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"

    copy_config
}

copy_config() {
    cp "${linux_src_path}/.config" "${working_dir}/configs/${system}/${local_version}" || { echo "${red}Error copying config to configs/${system}/${local_version}.${nc}"; exit 1; }
    ${working_dir}/scripts/replace_cmdline.sh || { echo "${red}Error replacing command line parameters.${nc}"; exit 1; }

    echo "${green}Copied ${local_version} successfully.${nc}"
}

rsync_latest_config() {
    tmp_file=$(mktemp)
    rsync "${system}:/usr/src/linux/.config" "${tmp_file}" || { echo "${red}Failed to sync config for ${system}.${nc}"; exit 1; }

    local_version="$(awk '/# Linux\/x86/ {print $3}' "${tmp_file}")-$(grep "^CONFIG_LOCALVERSION" "${tmp_file}" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"

    mv "${tmp_file}" "${working_dir}/configs/${system}/${local_version}"
    ${working_dir}/scripts/replace_cmdline.sh || { echo "${red}Error replacing command line parameters.${nc}"; exit 1; }

    echo "${green}Copied ${local_version} successfully.${nc}"
}

case ${1} in
    angelica)
        system="angelica"
        select_version
    ;;

    eleanore)
        system="eleanore"
        rsync_latest_config
    ;;

    kotori)
        system="kotori"
        select_version
    ;;

    *)
        echo "Unkown option: \"${1}\""
        echo "Correct Usuage: ${0} [SYSTEM]"
        echo "Available systems: angelica, eleanore, kotori"
    ;;
esac
