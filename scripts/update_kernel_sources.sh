#!/bin/sh

# update_kernel_sources.sh - Update kernel source directories. (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 1.0.0

new_kernel_ver="$(ls "/usr/src/" --hide="linux" | grep "linux")"
systems="angelica kotori"

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this shell script as root."
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
        echo "${new_kernel_ver} already exists for ${system}. Skipping...\n"
        continue
    fi

    # Copy the new kernel version to the source directory.
    echo "Copying ${new_kernel_ver} to ${src_path}/linux/..."
    cp -r "/usr/src/${new_kernel_ver}" "${src_path}/linux/" || { echo "Error copying ${new_kernel_ver} to ${system}'s kernel source directory."; exit 1; }
    echo "Successfully copied ${new_kernel_ver} to ${system}'s kernel source directory."

    # Copy the old configuration to the new source directory.
    prev_kernel_ver="$(ls "${src_path}/linux/" | sort -V | tail -n 2 | head -n 1)"

    cp "${src_path}/linux/${prev_kernel_ver}/.config" "${src_path}/linux/${new_kernel_ver}/" || { echo "Error copying previous linux configuration to ${system}/${new_kernel_ver}"; exit 1; }
    echo "Successfully copied old kernel configuration to ${system}'s kernel source directory.\n"

    # Ask if user wants to do a make oldconfig.
    while true; do
        read -p "Do you want to make oldconfig? (y/n): " make_oldconfig_ans
        case ${make_oldconfig_ans} in
            [Yy]* ) 
                cd "${src_path}/linux/${new_kernel_ver}"

                make oldconfig || { echo "Error while doing make oldconfig for ${new_kernel_ver}"; exit 1; }

                prev_conf_local_ver="$(grep "^CONFIG_LOCALVERSION" ".config" | sed "s/^CONFIG_LOCALVERSION=\"-${system}-//" | tr -d '"')"

                while true; do
                    echo "The previous local version was ${prev_conf_local_ver} for ${prev_kernel_ver}. Please enter a new local version. \n"
                    read new_local_ver_ans
                    
                    if echo "${new_local_ver_ans}"  | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
                        sed -i "s/-${system}-${prev_conf_local_ver}/-${system}-${new_local_ver_ans}/" ".config" || { echo "Error writing new local version."; exit 1; }
                        echo "Successfully updated local version for ${system}/${new_local_ver_ans}.\n"

                        break
                    else
                        echo "Please enter a valid version string. \n"
                    fi
                done

                break
            ;;
    
            [Nn]* )
                echo "Skipping make oldconfig for ${system}...\n"
                break
            ;;
    
            * )
                echo "Please answer yes or no."
            ;;
        esac
    done
done

# Update symlink for kotori.
rm /usr/src/linux || { echo "Removing old symlink to ${prev_kernel_ver}"; exit 1; }
ln -s "${src_path}/kotori/${new_kernel_ver}/" "/usr/src/linux" || { echo "Error creating symlink to new kotori linux source directory."; exit 1; }
echo "Sucessfully created /usr/src/linux symlink to ${src_path}/kotori/${new_kernel_ver} \n"
