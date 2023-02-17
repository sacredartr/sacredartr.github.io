---
title: "Linux Daily Tips"
date: 2022-08-16
author: "sacredartr"
description: "Linux tips for daily use"
tags: ["linux"]
categories: ["linux", "tips"]
series: ["Linux Tips"]
aliases: ["linux-daily-tips"]
ShowToc: true
TocOpen: true
---

# Linux Daily Tips

## 文件清空
```console
cat /dev/null > file
```

## xargs 
```console
ls ./* | xargs -i cp {} /tmp/
```

## sed
```console
sed -i 's/password: .*/password: 123456/g' file
```

## awk
```console
cat file | awk '$1 ~ /th/ {print $1}'
```

## 执行命令忽略报错信息
```console
unalias cp 2>/dev/null || true
```

## 文件追加内容
```console
echo 'content' >> file
```

## 登陆获取token
```console
token=$(curl -X POST "http://$external_ip/api/v1/login" --header 'Content-Type: application/json' --data '{"username": "root","password": "******"}' | awk -F"[,:}]" '{for(i=1;i<=NF;i++){print $(i+1)}}' | tr -d '"' | sed -n 1p)
```

## 执行命令时输入
```console
echo yes | sh deploy.sh
```

## 文件尾部追加内容
```console
cat>>/etc/profile<<EOF
export no_proxy="localhost, 127.0.0.1"
EOF
```
## 文件任意位置追加内容
```console
sed -i "21i EnvironmentFile=/etc/clash/env" /etc/systemd/system/containerd.service
```