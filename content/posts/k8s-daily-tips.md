---
title: "K8S Daily Tips"
date: 2022-11-18
author: "sacredartr"
description: "K8S tips for daily use"
tags: ["k8s"]
categories: ["k8s", "tips"]
series: ["k8s Tips"]
aliases: ["k8s-daily-tips"]
ShowToc: true
TocOpen: true
---

# K8S Daily Tips

## docker add proxy
```shell
cat>>/etc/profile<<EOF
export http_proxy=http://$IP:7890
export https_proxy=http://$IP:7890
export no_proxy="localhost, 127.0.0.1"
EOF
source /etc/profile
rm -rf /etc/clash/env
mkdir -pv /etc/clash
cat>/etc/clash/env<<EOF
http_proxy=http://$IP:7890
https_proxy=http://$IP:7890
no_proxy="localhost, 127.0.0.1"
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

## containerd add proxy
```shell
cat>>/etc/profile<<EOF
export http_proxy=http://$IP:7890
export https_proxy=http://$IP:7890
export no_proxy="localhost, 127.0.0.1"
EOF
source /etc/profile
rm -rf /etc/clash/env
mkdir -pv /etc/clash
cat>/etc/clash/env<<EOF
http_proxy=http://$IP:7890
https_proxy=http://$IP:7890
no_proxy="localhost, 127.0.0.1"
EOF
sed -i "21i EnvironmentFile=/etc/clash/env" /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl restart containerd
```

## K8S logs container in pod
```console
kubectl get pods xxx -o jsonpath={.spec.containers[*].name} -n kube-system
kubectl logs xxx -c xxxx -n kube-system
```