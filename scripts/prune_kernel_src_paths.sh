#!/bin/sh

# prune_kernel_src_paths.sh - Prune deprecated kernel source directories from /usr/local/src/ (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.0.0

systems="angelica kotori"

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

for system in ${systems}
do
    kernel_src_path="/usr/local/src/${system}/linux/"
    kernel_path="$(ls "${kernel_src_path}" | sort -V)"

    if [ $(echo ${kernel_path} | wc -w) -le 2 ]; then
        echo "${kernel_src_path} has already been pruned. Skipping...\n"
        continue
    fi

    keep_kernel_path="$(echo "${kernel_path}" | tail -n 2 | xargs)"
    remove_kernel_path="$(echo "${kernel_path}" | head -n -2 | xargs)"

    echo "Commencing pruning of ${kernel_src_path}."
    echo "Keeping: ${keep_kernel_path}."
    echo "Removing: ${remove_kernel_path}."

    while true; do
        read -p "Do you want to continue? (y/n): " answer
        case ${answer} in
            [Yy]* ) 
                echo "Removing deprecated kernel source directories...\n"

                for i in ${remove_kernel_path}
                do
                    rm -r "${i}" || { echo "Error removing folder ${i}."; exit 1; }
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
done
