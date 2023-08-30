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

## clear file
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

## ignore error message
```console
unalias cp 2>/dev/null || true
```

## append content to file
```console
echo 'content' >> file
```

## login to get token
```
token=$(curl -X POST "http://$external_ip/api/v1/login" --header 'Content-Type: application/json' --data '{"username": "root","password": "******"}' | awk -F"[,:}]" '{for(i=1;i<=NF;i++){print $(i+1)}}' | tr -d '"' | sed -n 1p)
```

## input when executing command
```console
echo yes | sh deploy.sh
```

## append content to end of file
```console
cat>>/etc/profile<<EOF
export no_proxy="localhost, 127.0.0.1"
EOF
```

## append content to anywhere in the file
```console
sed -i "21i EnvironmentFile=/etc/clash/env" /etc/systemd/system/containerd.service
```


## execute shell on ssh command
```console
ssh -i ~/.ssh/key root@${HOST_IP} 'bash -s' << 'END'
kubectl patch  svc demo -n demo --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"add","path":"/spec/ports/0/nodePort","value":30011}]'
END
```

