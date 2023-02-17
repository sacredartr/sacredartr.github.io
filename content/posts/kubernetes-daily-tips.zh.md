---
title: "Kubernetes Daily Tips"
date: 2022-08-18
author: "sacredartr"
description: "Kubernetes tips for daily use"
tags: ["kubernetes"]
categories: ["kubernetes", "tips"]
series: ["Kubernetes Tips"]
aliases: ["kubernetes-daily-tips"]
ShowToc: true
TocOpen: true
---

# Kubernetes Daily Tips

## docker 添加代理
```shell
cat>>/etc/profile<<EOF
export http_proxy=http://$IP:7890
export https_proxy=http://$IP:7890
export no_proxy="localhost, 127.0.0.1, 10.244.0.0/18"
EOF
source /etc/profile
rm -rf /etc/clash/env
mkdir -pv /etc/clash
cat>/etc/clash/env<<EOF
http_proxy=http://$IP:7890
https_proxy=http://$IP:7890
no_proxy="localhost, 127.0.0.1, 10.244.0.0/18"
EOF
mkdir -pv /etc/systemd/system/docker.service.d
rm -rf /etc/systemd/system/docker.service.d/proxy.conf
cat>/etc/systemd/system/docker.service.d/proxy.conf<<EOF
[Service]
EnvironmentFile=/etc/clash/env
EOF
systemctl daemon-reload
systemctl restart docker
```

## containerd 添加代理
```shell
cat>>/etc/profile<<EOF
export http_proxy=http://$IP:7890
export https_proxy=http://$IP:7890
export no_proxy="localhost, 127.0.0.1, 10.244.0.0/18"
EOF
source /etc/profile
rm -rf /etc/clash/env
mkdir -pv /etc/clash
cat>/etc/clash/env<<EOF
http_proxy=http://$IP:7890
https_proxy=http://$IP:7890
no_proxy="localhost, 127.0.0.1, 10.244.0.0/18"
EOF
sed -i "21i EnvironmentFile=/etc/clash/env" /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl restart containerd
```
