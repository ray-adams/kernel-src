#!/bin/sh

# replace_cmdline.sh - replace sensitive command line options from kernel config

# Copyright 2024 Ray Adams
# SPDX-License-Identifier: BSD-3-Clause

# Version: 1.0.0

working_dir="$(git rev-parse --show-toplevel)"

cd ${working_dir}

angelica_cmd_line="rd.luks.uuid=<luks_uuid> rd.luks.name=<luks_uuid>=musl-root root=UUID=<root_uuid> nosmt=force intel_iommu=on"
eleanore_cmd_line="root=PARTUUID=<root_partuuid> nosmt=force"
kotori_cmd_line="rd.luks.uuid=<luks_uuid> rd.luks.name=<luks_uuid>=musl-root root=UUID=<root_uuid> nosmt=force intel_iommu=on"

find "./systems/angelica/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${angelica_cmd_line}\"/" {} + \
    || { echo "Error replacing angelica command line parameters."; exit 1; }
find "./systems/eleanore/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${eleanore_cmd_line}\"/" {} + \
    || { echo "Error replacing eleanore command line parameters."; exit 1; }
find "./systems/kotori/" -type f -exec sed -i "s/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${kotori_cmd_line}\"/" {} + \
    || { echo "Error replacing kotori command line parameters."; exit 1; }

echo "Finished replacing command line parameters."
