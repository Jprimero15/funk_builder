#!/bin/bash

MANIFEST="https://gitlab.com/OrangeFox/sync.git"
OEM="xiaomi"
DEVICE="mi439"
DT_LINK="https://github.com/Jprimero15/recovery_device_xiaomi_olive.git"
DT_PATH=device/${OEM}/${DEVICE}
BLDR="🦊 CI-Builder:"
#EXTRA_CMD=""

apt install openssh-server -y
apt update --fix-missing
apt install openssh-server -y

# Inlined function to post a message
export BOT_MSG_URL="https://api.telegram.org/bot${TG_TOKEN}/sendMessage"
function tg_msg() {
    curl -s -X POST "${BOT_MSG_URL}" -d chat_id="${TG_CHAT_ID}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"
}

tg_msg "<b>${BLDR} Setting up Build Environment</b>"


tg_msg "<b>${BLDR} Syncing OrangeFox Sources</b>"
git clone ${MANIFEST} ~/FOX && cd ~/FOX || exit
./orangefox_sync.sh --branch 11.0 --path ~/fox_11.0
cd ~/fox_11.0 || exit

# set timezone
export TZ="Asia/Manila"

git clone ${DT_LINK} ${DT_PATH}

# commit head
dt_commit="$(git -C ${DT_PATH} rev-parse HEAD)"
tg_msg "<b>${BLDR} GIT Device Tree HEAD: ${dt_commit}</b>"

#echo " ===+++ Running the Extra Command... +++==="
#$EXTRA_CMD

tg_msg "<b>${BLDR} Building OrangeFox Recovery</b>"
. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1
export LC_ALL="C"
lunch twrp_${DEVICE}-eng && mka recoveryimage

# Upload ofox zip
tg_msg "<b>${BLDR} Uploading OrangeFox Recovery</b>"

cd out/target/product/${DEVICE} || exit

# Set FILENAME var
OUTPUT="OrangeFox*.zip"
FILENAME="$(echo ${OUTPUT})"

curl -F "document=@${FILENAME}" --form-string "caption=<b>Build Target: <code>${DEVICE} Variant</code></b>
<b>Date: <code>$(date '+%B %d, %Y.') </code></b>
<b>Time: <code>$(date +'%r')</code></b>" "https://api.telegram.org/bot${TG_TOKEN}/sendDocument?chat_id=${TG_CHAT_ID}&parse_mode=html"

curl -sL https://git.io/file-transfer | sh
./transfer wet "${FILENAME}"
