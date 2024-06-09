#!/bin/sh

# copy_config.sh - copy kernel configuration

# Copyright 2024 Ray Adams
# SPDX-License-Identifier: BSD-3-Clause

# Version: 1.0.1

working_dir="$(git rev-parse --show-toplevel)"
src_path="/usr/local/src/"

cd ${working_dir}

select_version() {
    echo "Available Linux kernels:"
    ls "${src_path}/${system}/linux/"
    while true; do
        echo "Select a version:"
        read version
        if [ -d "${src_path}/${system}/linux/${version}" ]; then
            linux_src_path="${src_path}/${system}/linux/${version}/"
            break
        elif [ -d "${src_path}/${system}/linux/linux-${version}/" ]; then
            linux_src_path="${src_path}/${system}/linux/linux-${version}/"
            break
        else
            echo "Please choose a valid version."
        fi
    done

    local_version="$(echo ${version} | sed 's/linux-//')-$(grep "^CONFIG_LOCALVERSION" "${linux_src_path}/.config" | sed 's/^CONFIG_LOCALVERSION="-//' | tr -d '"')"

    copy_config
}

copy_config() {
    cp "${linux_src_path}/.config" "./configs/${system}/${local_version}" || { echo "Error copying config to configs/${system}/${local_version}."; exit 1; }
    ./scripts/replace_cmdline.sh || { echo "Error replacing command line parameters."; exit 1; }

    echo "Copied ${local_version} successfully."
}

case ${1} in
    angelica)
        system="angelica"
        select_version
    ;;

    kotori)
        system="kotori"
        select_version
    ;;

    *)
        echo "Unkown option."
    ;;
esac
