#!/bin/sh

# Script Name: prune_module_paths.sh
# File Path: <git_root>/scripts/prune_module_paths.sh
# Description: Prune deprecated kernel module directories (REQUIRES ROOT PRIVILAGES).

# Copyright 2024 Ray Adams
# SPDX-Licence-Identifier: BSD-3-Clause

# Version: 2.0.0

# Colors
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Check if the script was executed with root privilages.
if [ "$(id -u)" -ne 0 ]; then
    echo "${red}Please run this shell script as root.${nc}"
    exit 1
fi

remove_modules() {
    sorted_modules="$(ls "${module_path}" | sort -V)"

    # Check if directory is empty
    if [ $(echo ${sorted_modules} | wc -w) -le 2 ]; then
        echo "${green}${module_path} has already been pruned. Skipping...${nc}\n"
        exit 0
    fi
    
    # Show directories that are going to be removed
    keep_module_paths="$(echo "${sorted_modules}" | tail -n 2 | xargs)"
    remove_module_paths="$(echo "${sorted_modules}" | head -n -2 | xargs)"
    
    echo "${green}Commencing pruning of ${module_path}.${nc}"
    echo "${green}Keeping: ${keep_module_paths}.${nc}"
    echo "${green}Removing: ${remove_module_paths}.${nc}"

    # Ask user if they want to proceed
    while true; do
        echo "${green}Do you want to continue? (y/n): ${nc}"
        read answer
        case ${answer} in
            [Yy]* ) 
                echo "${green}Removing deprecated module directories...\n${nc}"
    
                for i in ${remove_module_paths}
                do
                    rm -r "${module_path}/${i}" || { echo "${red}Error removing folder ${module_path}/${i}.${nc}"; exit 1; }
                done
    
                break
            ;;
    
            [Nn]* )
                break
            ;;
    
            * )
                echo "${red}Please answer yes or no.${nc}"
            ;;
        esac
    done
}

# Allow the user to select which system to compile a kernel for.
case ${1} in
    angelica)
        module_path="/usr/local/src/angelica/modules/"
        remove_modules
    ;;

    current)
        module_path="/lib/modules/"
        remove_modules
    ;;

    *)
        echo "Unkown option: \"${1}\""
        echo "Correct Usuage: ${0} [OPTION]"
        echo "Available options: angelica, current"
    ;;
esac
