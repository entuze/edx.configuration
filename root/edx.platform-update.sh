#!/bin/bash
# Update edx-platform fork
# McDaniel
# Feb 2019
#
# Performs a refresh of the code base in edx-platform.
#
#
# This script takes around 40 minutes to complete.
#---------------------------------------------------------


cd ~


./edx.platform-stop.sh
rm -rf /edx/app/edxapp/edx-platform
/edx/bin/update edx-platform open-release/ironwood.master
./edx.install-config.sh
./edx.compile-assets.sh
./edx.platform-restart-full.sh
