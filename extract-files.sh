#!/bin/bash
#
# Copyright (C) 2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

VENDOR=nokia
DEVICE=DRG

# Load extractutils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

if [ $# -eq 0 ]; then
  SRC=adb
else
  if [ $# -eq 1 ]; then
    SRC=$1
  else
    echo "$0: bad number of arguments"
    echo ""
    echo "usage: $0 [PATH_TO_EXPANDED_ROM]"
    echo ""
    echo "If PATH_TO_EXPANDED_ROM is not specified, blobs will be extracted from"
    echo "the device using adb pull."
    exit 1
  fi
fi

function blob_fixup() {
    case "${1}" in
    vendor/lib64/hw/camera.sdm660.so)
        patchelf --remove-needed "libMegviiFacepp.so" "${2}"
        patchelf --remove-needed "libmegface-new.so" "${2}"
        patchelf --add-needed "libshim_megvii.so" "${2}"
        ;;
        # Fix xml version
    vendor.qti.hardware.data.connection-V1.0-java.xml|vendor.qti.hardware.data.connection-V1.1-java.xml)
        sed -i 's/xml version="2.0"/xml version="1.0"/' "${2}"
        ;;
    product/lib64/libdpmframework.so)
        patchelf --replace-needed "libcutils.so" "libcutils-v29.so" "${2}"
        patchelf --add-needed "libcutils.so" "${2}"
        ;;
    vendor/etc/nfcee_access.xml)
        sed -i 's|xliff="urn:oasis:names:tc:xliff:document:1.2"|android="http://schemas.android.com/apk/res/android"|' "${2}"
        ;;
    esac
}

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"

# Initialize the helper for device
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT"

extract "$MY_DIR"/proprietary-files.txt "$SRC"

"$MY_DIR"/setup-makefiles.sh
