#!/bin/bash
MANIFEST="https://gitlab.com/OrangeFox/sync.git"
OEM="xiaomi"
DEVICE="mi439"
DT_LINK="https://github.com/Jprimero15/recovery_device_xiaomi_olive.git"
DT_PATH=device/$OEM/$DEVICE
#EXTRA_CMD=""

echo " ===+++ Setting up Build Environment +++==="
apt install openssh-server -y
apt update --fix-missing
apt install openssh-server -y

echo " ===+++ Sync OrangeFox +++==="
git clone $MANIFEST ~/FOX && cd ~/FOX
./orangefox_sync.sh --branch 11.0 --path ~/fox_11.0
cd ~/fox_11.0
git clone $DT_LINK $DT_PATH

echo " ===+++ Running the Extra Command... +++==="
#$EXTRA_CMD

echo " ====+++ Building OrangeFox... +++==="
. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1
export LC_ALL="C"
lunch twrp_${DEVICE}-eng && mka recoveryimage

# Upload zips & recovery.img
#echo " ===+++ Uploading Recovery +++===
cd out/target/product/$DEVICE

curl -sL https://git.io/file-transfer | sh
./transfer wet OrangeFox*.zip
