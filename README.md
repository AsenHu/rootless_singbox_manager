# rootless_singbox_manager


## singbox 自动构建 builder.sh

这个脚本无需 root，有 go 环境会用 go 编译，没 go 就在 `$HOME/GO` 装一个 go 临时用于编译。直接运行就可以在当前目录下获得一个 singbox 二进制，默认编译 latest 分支，带除了需要 cgo 和 ssr 的所有 tag。

这个脚本会在运行目录放 `builder.sh` `sing-box` 两个文件和 `tmp` 缓存文件夹。因为会生成一些文件在运行目录，所以建议新建文件夹运行脚本。

这个命令会在 `$HOME/SINGBOX` 运行脚本。

```
mkdir -p ~/SINGBOX && cd ~/SINGBOX && bash <(curl https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/builder.sh)
```

第三方

```
mkdir -p ~/SINGBOX && cd ~/SINGBOX && bash <(curl https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/reF1nd_builder.sh)
```

脚本有两个参数 `--branches=xxx` 和 `--tags=xxx`，可以简写为 `-b=xxx` `-t=xxx`。branches 有两个选项 latest 和 dev-next，默认前者，tags 默认除了需要 cgo 和 ssr 的所有 tag。

默认的命令与这个等效

```
mkdir -p ~/SINGBOX && cd ~/SINGBOX && builder.sh -b=latest -t=with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_acme,with_clash_api,with_v2ray_api,with_gvisor
```

记得写个 crontab 定时运行这个脚本

```
# 每天凌晨四点运行一次 builder.sh
0 4 * * * /bin/bash /home/admin/SINGBOX/builder.sh
```

## 自动更新 singbox 为最新的编译版本 systemd.sh

仅支持 systemd

随便找个目录下载进去，用 crontab 每天运行就行了。只有在确定有更新的时候才会替换。脚本第一个参数必须传入，这里是构建好的 singbox 二进制文件，第二个参数是 bin 下面的 singbox 二进制文件，默认 `/user/bin/singbox`

直接安装 + 运行

```
cd ~ && bash <(curl https://raw.githubusercontent.com/AsenHu/rootless_singbox_manager/main/systemd.sh) /home/admin/SINGBOX/sing-box /usr/bin/sing-box
```

crontab
```
# 每天凌晨四点半运行一次
30 4 * * * /bin/bash /root/systemd.sh /home/admin/SINGBOX/sing-box /usr/bin/sing-box
```
