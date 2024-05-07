#!/bin/bash

##
## Copyright © 2020-2024 David Čuka and Stephen Čuka All Rights Reserved.
##
## FireMyPi is licensed under the Creative Commons Attribution-NonCommercial-
## NoDerivatives 4.0 International License (CC BY-NC-ND 4.0).
##
## The full text of the license can be found in the included LICENSE file 
## or at https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode.en.
##
## For the avoidance of doubt, FireMyPi is for personal use only and may not 
## be used by or for any business in any way.
##

#
# FireMyPi:	get-image-from-Downloads.sh
#

#
# Clean the build environment and get the most recent IPFire core image
# from the users Downloads directory.
#

PNAME=`basename $0`
if [[ ! -e "${PWD}/${PNAME}" ]]
then
        echo "Wrong directory - change to build directory and retry"
        exit 1
fi

source fmp-common

IMAGEDIR="$1"
HAVEIMAGE=no

if [[ -z "${IMAGEDIR}" ]]
    then
        IMAGEDIR="/home/${USER}/Downloads"
fi

clear

header Get IPFire Core Image

COUNT=`ls image/ipfire*-aarch64.img 2>/dev/null | wc -l`

if [[ ${COUNT} != 0 ]] && [[ -e "core-image-to-use.yml" ]]
then
	HAVEIMAGE=yes
	echo -e "You already have a core image in the build environment:\n"
	IMAGE=`ls -t image/ipfire*-aarch64.img | head -n 1 | rev | cut -d / -f 1 | rev`
	echo -e "\t${GRN}${IMAGE}${NC}\n"
	echo -e "Do you want to replace ${IMAGE}?\n"
	read -p "Type 'yes' to replace the current image: " YES
	echo ""
	if [[ ${YES} != "yes" ]]
	then
		abort Cancelled.
	fi
fi

COUNT=`ls ${IMAGEDIR}/ipfire*-aarch64.img.xz 2>/dev/null | wc -l`

while [[ ${COUNT} == 0 ]]
do
        echo -e "No images found in ${IMAGEDIR}...\n"
	echo -e "Enter the directory to search for IPFire images or <Ctrl-C> to exit:\n"
	read IMAGEDIR
	if [[ "${IMAGEDIR:0:1}" == "~" ]]
	then
		IMAGEDIR=${HOME}${IMAGEDIR:1}
	fi
	COUNT=`ls ${IMAGEDIR}/ipfire*-aarch64.img.xz 2>/dev/null | wc -l`
	echo -e ""
done

echo -e "Here is a list of the images in ${IMAGEDIR}: "
ls -1 ${IMAGEDIR}/ipfire*-aarch64.img.xz

cat << HERE

The most recently downloaded image, shown below, will be copied into
the build environment.  You can select another image from the list
above by exiting this script and doing a 'touch <image>' to update
the image file timestamp before re-running this script.

HERE

IMAGE=`ls -t ${IMAGEDIR}/ipfire*-aarch64.img.xz | head -n 1 | rev | cut -d / -f 1 | rev`
echo -e "\t${GRN}${IMAGE}${NC}\n"

read -p "Press <Enter> to continue or <Ctrl-C> to exit: "

if [[ ${HAVEIMAGE} == "yes" ]]
then
	echo -e ""
	./clean.sh --coreimage
fi

echo -e "\nCopying image from ${IMAGEDIR} to image directory...\n"
cp "${IMAGEDIR}/${IMAGE}" image

echo -e "Decompressing image...\n"
cd image
unxz -kf "${IMAGE}"
cd ..

echo -e "Setting new image in core-image-to-use file...\n"
COREIMAGE=`basename ${IMAGE} .xz`
CORENUMBER=`echo ${IMAGE} | cut -d- -f3 | cut -de -f2`
echo -e "---" > core-image-to-use.yml
echo -e "#" >> core-image-to-use.yml
echo -e "# core image is set here by get-image-from-Downloads.sh" >> core-image-to-use.yml
echo -e "#" >> core-image-to-use.yml
echo -e "" >> core-image-to-use.yml
echo -e "    core_image: \"{{builddir}}/image/${COREIMAGE}\"" >> core-image-to-use.yml
echo -e "    core_number: ${CORENUMBER}" >> core-image-to-use.yml
echo -e "" >> core-image-to-use.yml
echo -e "..." >> core-image-to-use.yml

echo -e "Done."
exit 0
