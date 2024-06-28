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
nerdctl -n k8s.io save -o images.tar.gz docker.io/busybox:latest
nerdctl -n k8s.io load -i images.tar.gz
nerdctl -n k8s.io pull docker.io/busybox:latest
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
Method one
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
Method two
```console
node02 broken
1. 【node01】kubectl drain node02
2. 【node01】kubectl delete node node02
3. 【node02】kubeadm reset -f (systemctl stop containerd  #if pedding)
4. 【node02】edit node02 /etc/hosts，apiserver.cluster.local:node02IP -> apiserver.cluster.local:node01IP
5. 【node01】kubeadm token create --print-join-command
6. 【node01】kubeadm init phase upload-certs --upload-certs --v=5
7. 【node02】kubeadm join apiserver.cluster.local:6443 --token xxxxx --discovery-token-ca-cert-hash xxxxxxx --control-plane --certificate-key xxxxxxxx --v=5
8. 【node02】edit node02 /etc/hosts，apiserver.cluster.local:node02IP -> apiserver.cluster.local:node01IP
```
Method three
```console
node02 broken
1. 【node02】mv /etc/kubernetes/manifests/* ./manifests/
2. 【node02】rm -rf /var/lib/etcd/*
3. 【node02】mv ./manifests/* /etc/kubernetes/manifests/
```

## local-path storageclass
[local-path.yaml](https://github.com/sacredartr/sacredartr.github.io/blob/master/config-yaml/storageclass/local-path.yaml)
```console
mkdir -pv /data/local-path-provisioner
kubectl apply -f local-path.yaml
```

## update Kubernetes certificates
```console
【all node】
kubeadm certs check-expiration
mkdir -pv /etc/kubernetes-bak
cp -r /etc/kubernetes/* /etc/kubernetes-bak
kubeadm certs renew all --v=5
mv $HOME/.kube/config $HOME/.kube/config.old
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
mkdir /root/bak
mv /etc/kubernetes/manifests/* /root/bak/
mv /root/bak/* /etc/kubernetes/manifests/
rm -rf /root/bak
kubeadm certs check-expiration
```

## migrate containerd
```console
sudo systemctl stop containerd
cd /etc
tar -zcvf containerd.tar.gz containerd
tar -zxvf containerd.tar.gz -C /data
ln -s /data/containerd /etc/containerd
sudo systemctl start containerd
```

## k8s join configure
```console
systemctl stop firewalld || true
systemctl disable firewalld || true
setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
modprobe br_netfilter && modprobe nf_conntrack
cat > /etc/sysctl.d/98-k8s.conf << EOF
net.netfilter.nf_conntrack_tcp_be_liberal = 1
net.netfilter.nf_conntrack_tcp_loose = 1
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 131072
net.netfilter.nf_conntrack_tcp_timeout_established = 21600
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 4096
vm.max_map_count = 262144
net.ipv4.ip_forward = 1
net.ipv4.tcp_timestamps = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.forwarding=1
fs.file-max=1048576
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
EOF
cat > /etc/security/limits.d/98-k8s.conf << EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
sysctl --system
sysctl -p
swapoff -a
sed -i /swap/d /etc/fstab
```