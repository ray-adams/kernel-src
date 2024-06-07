#!/bin/sh

# prune_uki_paths.sh - Prune deprecated unified kernel images (UKIs) from /usr/src/uki (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.0.0

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
    exit 1
fi

for system in ${systems}
do
    uki_src_path="/usr/local/src/${system}/uki/"
    uki_sorted="$(ls "${uki_src_path}" | sort -V)"

    if [ $(echo ${uki_sorted} | wc -w) -le 2 ]; then
        echo "${uki_src_path} has already been pruned. Skipping...\n"
        continue
    fi

    keep_uki="$(echo "${uki_sorted}" | tail -n 2 | xargs)"
    remove_uki="$(echo "${uki_sorted}" | head -n -2 | xargs)"

    echo "Commencing pruning of ${uki_src_path}."
    echo "Keeping: ${keep_uki}."
    echo "Removing: ${remove_uki}."

    while true; do
        read -p "Do you want to continue? (y/n): " answer
        case ${answer} in
            [Yy]* ) 
                echo "Removing deprecated kernel source directories...\n"

                for i in ${remove_uki}
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
