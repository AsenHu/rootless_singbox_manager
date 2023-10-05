#!/usr/bin/env bash

singboxExe=$1
binPathExe=$2

if [ ! "$singboxExe" ]
then
    echo "There is no compiled singbox program."
    exit 1
fi

if [ ! "$binPathExe" ]
then
    binPathExe=/usr/bin/sing-box
fi

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

cp_singbox() {
    local buildVer binVer
    buildVer=$(sha512sum "$singboxExe" | awk -F " " '{print $1}')
    binVer=$(sha512sum "$binPathExe" | awk -F " " '{print $1}')
    if [ "$buildVer" ]
    then
        if [ "$buildVer" != "$binVer" ]
        then
            groupadd --system sing-box
            useradd --system --gid sing-box --create-home --home-dir /var/lib/sing-box --shell /usr/sbin/nologin sing-box
            if [ ! -f /var/lib/sing-box/config.json ]
            then
                echo "{}" > /var/lib/sing-box/config.json
            fi
            if ! "$singboxExe" check --config /var/lib/sing-box/config.json
            then
                mv -b /var/lib/sing-box/config.json /var/lib/sing-box/config.json.badconfig
                echo "{}" > /var/lib/sing-box/config.json
            fi
            systemctl stop sing-box
            cp -f "$singboxExe" "$binPathExe"
            curl -o sing-box.service https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/sing-box.service
            mv ./sing-box.service /usr/lib/systemd/system/sing-box.service
            systemctl daemon-reload
            systemctl enable --now sing-box
        fi
    fi
}

check_update() {
    local dir latest_scr_VERSION local_scr_VERSION
    dir=$(pwd)
    if [ ! -f "$dir/systemd.sh" ]
    then
        curl -o "$dir/systemd.sh" https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/systemd.sh
        chmod +x "$dir/systemd.sh"
    else
        latest_scr_VERSION=$(curl -sL https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/systemd_version.txt)
        local_scr_VERSION=1.0.0
        if [ "$latest_scr_VERSION" != "$local_scr_VERSION" ]
        then
            rm -rf "$dir/systemd.sh"
            curl -o "$dir/systemd.sh" https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/systemd.sh
            chmod +x "$dir/systemd.sh"
        fi
    fi
}

main() {
    check_update
    cp_singbox
}

main
