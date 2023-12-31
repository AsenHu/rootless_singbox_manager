#!/usr/bin/env bash

mkdir -p tmp
touch ./tmp/singboxLocaLatestVersion
touch ./tmp/singboxLocalDevNextVersion

branches=latest
tags=with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_acme,with_clash_api,with_v2ray_api,with_gvisor

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

install_go_scr() {
    local GO_PATH status tmp errMes
    GO_PATH="$HOME/GO"
    if ! "$GO_PATH/install.sh" version > /dev/null
    then
        tmp=$(bash <(curl https://raw.githubusercontent.com/AsenHu/rootless_go_manager/main/install.sh) @ install "--path=$GO_PATH")
    else
        tmp=$("$GO_PATH/install.sh" @ install "--path=$GO_PATH")
    fi

    status=$(echo "$tmp" |cut -d':' -f1)

    if [ "$status" == "ERROR" ]
    then
        errMes=$(echo "$tmp" |cut -d':' -f2)
        echo "ERROR: $errMes"
        exit 1
    fi

    if [ "$status" == "SCRIPT" ]
    then
        PATH="$PATH:$GO_PATH/go/bin"
    fi
    singboxPath=$GO_PATH/go/bin/sing-box
}

get_singbox_version() {
    local branches
    branches=$1
    if [ "$branches" == latest ]
    then
        singLateVer() {
            if [ ! "$sing_latest_version" ]
            then
                sing_latest_version=$(curl -sL https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
            fi
            echo "$sing_latest_version"
        }
        singLocalVer=$(<./tmp/singboxLocaLatestVersion)
    fi
    if [ "$branches" == dev-next ]
    then
        singLateVer() {
            if [ ! "$sing_devNext_version" ]
            then
                sing_devNext_version=$(curl -sL https://api.github.com/repos/SagerNet/sing-box/commits | grep "sha" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
            fi
            echo "$sing_devNext_version"
        }
        singLocalVer=$(<./tmp/singboxLocalDevNextVersion)
    fi
}

singbox_update() {
    local branches tags
    branches=$1
    tags=$2
    get_singbox_version "$branches"
    if [ "$(singLateVer)" != "$singLocalVer" ]
    then
        go install -v -tags "$tags" "github.com/sagernet/sing-box/cmd/sing-box@$branches"
        if "$singboxPath" version
        then
            mv -f "$singboxPath" "./tmp/$branches"
            save_sing_version "$branches" "$(singLateVer)"
        fi
    fi
    cp -f "./tmp/$branches" ./sing-box
}

save_sing_version() {
    local branches version
    branches=$1
    version=$2
    if [ "$branches" == latest ]
    then
        echo "$version" > ./tmp/singboxLocaLatestVersion
    fi
    if [ "$branches" == dev-next ]
    then
        echo "$version" > ./tmp/singboxLocalDevNextVersion
    fi
}

check_update() {
    local dir latest_scr_VERSION local_scr_VERSION
    dir=$(pwd)
    if [ ! -f "$dir/builder.sh" ]
    then
        curl -o "$dir/builder.sh" https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/builder.sh
        chmod +x "$dir/builder.sh"
    else
        latest_scr_VERSION=$(curl -sL https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/build_version.txt)
        local_scr_VERSION=1.0.2
        if [ "$latest_scr_VERSION" != "$local_scr_VERSION" ]
        then
            rm -rf "$dir/tmp_builder.sh"
            curl -o "$dir/tmp_builder.sh" https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/builder.sh
            mv -f tmp_builder.sh builder.sh
            chmod +x "$dir/builder.sh"
        fi
    fi
}

main() {
    check_update
    install_go_scr
    singbox_update "$branches" "$tags"
}

for arg in "$@"; do
  case $arg in
    -b=*)
      branches="${arg#*=}"
      ;;
    -t=*)
      tags="${arg#*=}"
      ;;
    --branches=*)
      branches="${arg#*=}"
      ;;
    --tags=*)
      tags="${arg#*=}"
      ;;
  esac
done

main
