#!/bin/sh

# Script Name: update_kernel_sources.sh
# File Path: <git_root>/scripts/update_kernel_sources.sh
# Description: Update kernel source directories in /usr/local/src/ (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.0.0

new_kernel_ver="$(ls "/usr/src/" --hide="linux" | grep "linux")"
systems="angelica kotori"

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "${red}Please run this shell script as root.${nc}"
    exit 1
fi

# Remove old kernel sources in /usr/src/
EMERGE_DEFAULT_OPTS="" emerge --prune --nodeps sys-kernel/vanilla-sources

# For loop runs commands for all systems listed in variable.
for system in ${systems}
do
    src_path="/usr/local/src/${system}/"
    # Check if kernel source already exists. If so skip.
    if [ -d "${src_path}/linux/${new_kernel_ver}" ]; then
        echo "${green}${new_kernel_ver} already exists for ${system}. Skipping...${nc}\n"
        continue
    fi

    # Copy the new kernel version to the source directory.
    echo "${green}Copying ${new_kernel_ver} to ${src_path}/linux/...${nc}"
    cp -r "/usr/src/${new_kernel_ver}" "${src_path}/linux/" || { echo "${red}Error copying ${new_kernel_ver} to ${system}'s kernel source directory.${nc}"; exit 1; }
    echo "${green}Successfully copied ${new_kernel_ver} to ${system}'s kernel source directory.${nc}"

    # Copy the old configuration to the new source directory.
    prev_kernel_ver="$(ls "${src_path}/linux/" | sort -V | tail -n 2 | head -n 1)"

    cp "${src_path}/linux/${prev_kernel_ver}/.config" "${src_path}/linux/${new_kernel_ver}/" || { echo "${red}Error copying previous linux configuration to ${system}/${new_kernel_ver}${nc}"; exit 1; }
    echo "${green}Successfully copied old kernel configuration to ${system}'s kernel source directory.${nc}\n"

    # Ask if user wants to do a make oldconfig.
    while true; do
        echo "${green}Do you want to make oldconfig? (y/n):${nc}"
        read make_oldconfig_ans
        case ${make_oldconfig_ans} in
            [Yy]* ) 
                cd "${src_path}/linux/${new_kernel_ver}"

                make oldconfig || { echo "${red}Error while doing make oldconfig for ${new_kernel_ver}${nc}"; exit 1; }

                prev_conf_local_ver="$(grep "^CONFIG_LOCALVERSION" ".config" | sed "s/^CONFIG_LOCALVERSION=\"-${system}-//" | tr -d '"')"

                while true; do
                    echo "${green}The previous local version was ${prev_conf_local_ver} for ${prev_kernel_ver}. Please enter a new local version.${nc}"
                    read new_local_ver_ans
                    
                    if echo "${new_local_ver_ans}"  | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
                        sed -i "s/-${system}-${prev_conf_local_ver}/-${system}-${new_local_ver_ans}/" ".config" || { echo "${red}Error writing new local version.${nc}"; exit 1; }
                        echo "${green}Successfully updated local version for ${system}/${new_local_ver_ans}.${nc}\n"

                        break
                    else
                        echo "${red}Please enter a valid version string.${nc}"
                    fi
                done

                break
            ;;
    
            [Nn]* )
                echo "${green}Skipping make oldconfig for ${system}...${nc}\n"
                break
            ;;
    
            * )
                echo "${red}Please answer yes or no.${nc}"
            ;;
        esac
    done
done

# Update symlink for kotori.
rm /usr/src/linux || { echo "${red}Failed to remove old symlink to ${prev_kernel_ver}.${nc}"; exit 1; }
ln -s "${src_path}/linux/${new_kernel_ver}/" "/usr/src/linux" || { echo "${red}Error creating symlink to new kotori linux source directory.${nc}"; exit 1; }
echo "${green}Sucessfully created /usr/src/linux symlink to ${src_path}/linux/${new_kernel_ver}${nc}"
