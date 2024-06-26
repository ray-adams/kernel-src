#!/bin/sh

# Script Name: prune_module_paths.sh
# File Path: <git_root>/scripts/prune_module_paths.sh
# Description: Prune deprecated kernel module directories from /lib/modules/ (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.2.2

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

module_path="$(ls "/lib/modules/" | sort -V)"

if [ $(echo ${module_path} | wc -w) -le 2 ]; then
    echo "/lib/modules/ has already been pruned. Skipping...\n"
    exit 0
fi

keep_module_path="$(echo "${module_path}" | tail -n 2 | xargs)"
remove_module_path="$(echo "${module_path}" | head -n -2 | xargs)"

echo "Commencing pruning of /lib/modules/."
echo "Keeping: ${keep_module_path}."
echo "Removing: ${remove_module_path}."

while true; do
    read -p "Do you want to continue? (y/n): " answer
    case ${answer} in
        [Yy]* ) 
            echo "Removing deprecated module directories...\n"

            for i in ${remove_module_path}
            do
                rm -r "/lib/modules/${i}" || { echo "Error removing folder /lib/modules/${i}."; exit 1; }
            done

            break
        ;;

        [Nn]* )
            echo "Exiting...\n"

            break
        ;;

        * )
            echo "Please answer yes or no."
        ;;
    esac
done
