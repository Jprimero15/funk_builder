#!/bin/bash

MANIFEST="https://gitlab.com/OrangeFox/sync.git"
OEM="xiaomi"
DEVICE="olive"
DT_LINK="https://github.com/Jprimero15/recovery_device_xiaomi_olive.git"
DT_PATH="device/${OEM}/${DEVICE}"
RSOURCE="twrp"
IMGTARGET="recoveryimage"
CUSTOM_REC="OrangeFox"
OUTPUT="${CUSTOM_REC}*.zip"
BLDR="🦊 CI-Builder:"

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


tg_msg "<b>${BLDR} Syncing ${CUSTOM_REC} Sources</b>"
git clone ${MANIFEST} ~/${CUSTOM_REC}_sync && cd ~/${CUSTOM_REC}_sync || exit
./orangefox_sync.sh --branch 11.0 --path ~/fox_11.0
cd ~/fox_11.0 || exit

# needed files
git clone https://github.com/LOLZKERNEL/mzic -b master ~/mzic || exit

# set timezone
export TZ="Asia/Manila" || tg_msg "<b>${BLDR} FAILED TO SET GMT+8 TIMEZONE</b>"
tztz="(GMT+8)"

git clone ${DT_LINK} -b fox_11.0-q ${DT_PATH}

# commit head
dt_commit="$(git -C ${DT_PATH} rev-parse HEAD)"
tg_msg "<b>${BLDR} GIT Device Tree HEAD: <code>${dt_commit}</code></b>"

tg_msg "<b>${BLDR} Building ${CUSTOM_REC} Recovery</b>"
. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL="C"
lunch ${RSOURCE}_${DEVICE}-eng && mka ${IMGTARGET}

# Upload zip
tg_msg "<b>${BLDR} Uploading ${CUSTOM_REC} Recovery</b>"

cd out/target/product/${DEVICE} || exit

# Set FILENAME var
FILENAME="$(echo ${OUTPUT})"

curl -F "document=@${FILENAME}" --form-string "caption=<b>Build Target: <code>${DEVICE} Variant</code></b>
<b>Date: <code>$(date '+%B %d, %Y') ${tztz}</code></b>
<b>Time: <code>$(date +'%r') ${tztz}</code></b>" "https://api.telegram.org/bot${TG_TOKEN}/sendDocument?chat_id=${TG_CHAT_ID}&parse_mode=html"

curl -sL https://git.io/file-transfer | sh
./transfer wet "${FILENAME}" > flink.txt  || tg_msg "<b>${BLDR} FAILED TO MIRROR BUILD</b>"
MR_LINK=$(cat flink.txt | grep Download | cut -d\  -f3)

tg_msg "<b>${BLDR}</b>
<b>MIRROR LINK: ${MR_LINK}</b>
<b>Date: <code>$(date '+%B %d, %Y') ${tztz}</code></b>"
