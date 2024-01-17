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

## patch
```shell
kubectl patch  svc mariadb -n demo --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"add","path":"/spec/ports/0/nodePort","value":30006}]'
kubectl patch  svc rabbitmq -n demo --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"add","path":"/spec/ports/0/nodePort","value":30007},{"op":"add","path":"/spec/ports/1/nodePort","value":30008},{"op":"add","path":"/spec/ports/2/nodePort","value":30009},{"op":"add","path":"/spec/ports/3/nodePort","value":30010}]'
```

## delete
```shell
kubectl delete --all deploy -n demo
kubectl delete --all statefulset -n demo
kubectl delete --all pod -n demo
kubectl delete --all pvc -n demo
kubectl delete --all pv -n demo
kubectl delete ns demo
```

## images
```shell
crictl rmi docker.io/busybox:latest
ctr -n k8s.io image export busybox.tar.gz docker.io/busybox:latest
ctr -n k8s.io image import busybox.tar.gz
ctr -n k8s.io image pull docker.io/busybox:latest
```

## rollout
```shell
kubectl rollout restart deploy busybox
```

## namespace delete failed
```console
1. kubect  delete crd resource -n caas --force
2. kubectl edit crd resource -n caas
   remove finalizer 
3. kubectl get namespace monitoring -o json > monitoring.json
   vi monitoring.json remove finalizer
   kubectl proxy
   curl -k -H "Content-Type: application/json" -X PUT --data-binary @monitoring.json http://127.0.0.1:8001/api/v1/namespaces/monitoring/finalize
```

## recover split-brain
```console
1.【all node】ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key --endpoints=https://node1_ip:2379,https://node2_ip:2379,https://node3_ip:2379 endpoint status --write-out=json | jq
find the nodes with a revision difference greater than 1000
2.【healthy node】ETCDCTL_API=3 etcdctl --endpoints=https://node_ip:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save healthy.bak
3.【all node】mv /etc/kubernetes/manifests/* ./manifests/
4.【all node】rm -rf /var/lib/etcd/*
5.【all node】ETCDCTL_API=3 etcdctl --name ${noden_name} --initial-cluster ${node1_name}=https://${node1_ip}:2380,${node2_name}=https://${node2_ip}:2380,${node3_name}=https://${node3_ip}:2380 --initial-cluster-token etcd-cluster-1 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt --initial-advertise-peer-urls https://${noden_ip}:2380 snapshot restore healthy.bak --data-dir /var/lib/etcd
6.【healthy node】ETCDCTL_API=3 etcdctl --endpoints=https://${node1_ip}:2379,https://${node2_ip}:2379,https://${node3_ip}:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint health
check etcd health
7.【all node】mv ./manifests/* /etc/kubernetes/manifests/
```