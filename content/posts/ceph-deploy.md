---
title: "Ceph Deploy"
date: 2022-12-19
author: "sacredartr"
description: "ceph deploy"
tags: ["ceph"]
categories: ["ceph", "deploy"]
series: ["Ceph Deploy"]
aliases: ["ceph-deploy"]
ShowToc: true
TocOpen: true
---

# Ceph Deploy

## prepare
```console
3 centos x86
|10.0.0.1|2C|4G|50G|mount 50G disk|
|10.0.0.2|2C|4G|50G|mount 50G disk|
|10.0.0.3|2C|4G|50G|mount50G disk|

hostnamectl set-hostname node1
hostnamectl set-hostname node2
hostnamectl set-hostname node3

cat >> /etc/hosts <<EOF
10.0.0.1 node1
10.0.0.2 node2
10.0.0.3 node3
EOF
```

## install dependent packages on 3 machine
```console
cat > /etc/yum.repos.d/ceph.repo <<EOF
[noarch] 
name=Ceph noarch 
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/noarch/ 
enabled=1 
gpgcheck=0 

[x86_64] 
name=Ceph x86_64 
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/x86_64/ 
enabled=1 
gpgcheck=0
EOF

systemctl disable --now firewalld
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
yum install -y chrony epel-release wget yum-utils
systemctl enable --now chronyd
yum install -y openssl-devel openssl-static zlib-devel lzma tk-devel xz-devel bzip2-devel ncurses-devel gdbm-devel readline-devel sqlite-devel gcc libffi-devel lvm2
```

## install python on 3 machine
```console
wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz
tar -xvf Python-3.7.0.tgz
mv Python-3.7.0 /usr/local && cd /usr/local/Python-3.7.0/
./configure
make
make install
ln -s /usr/local/Python-3.7.0/python /usr/bin/python3

cd
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum install docker-ce-19.03.9 -y
mkdir /etc/docker
echo '{"registry-mirrors": ["http://hub-mirror.c.163.com"]}'>/etc/docker/daemon.json
systemctl enable --now docker
```

## install ceph on node1
```console
curl https://raw.githubusercontent.com/ceph/ceph/v15.2.1/src/cephadm/cephadm -o cephadm
chmod +x cephadm
./cephadm add-repo --release octopus
./cephadm install
which cephadm
cephadm --help
cephadm bootstrap --mon-ip 10.0.0.1

mkdir -p /etc/ceph
touch /etc/ceph/ceph.conf
alias ceph='cephadm shell -- ceph'
cephadm add-repo --release octopus
cephadm install ceph-common
ssh-copy-id -f -i /etc/ceph/ceph.pub root@node2
ssh-copy-id -f -i /etc/ceph/ceph.pub root@node3
ceph orch host add node2 10.0.0.2
ceph orch host add node3 10.0.0.3
ceph orch host ls
ceph orch host label add node1 mon
ceph orch host label add node2 mon
ceph orch host label add node3 mon
ceph orch apply mon node1
ceph orch apply mon node2
ceph orch apply mon node3
```

## wait for 20 minutes and continue(docker ps on node2 and node3 then deploy on node1)
```console
ceph orch daemon add osd node1:/dev/sdb
ceph orch daemon add osd node2:/dev/sdb
ceph orch daemon add osd node3:/dev/sdb
ceph orch device ls
ceph -s
```

## use ceph pool on k8s
```console
ceph osd pool create kubernetes 2 2
rbd pool init kubernetes
ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
ceph mon dump
```

## parameter description
```console
kubernetes：pool name
key: pool key
fsid: ceph k8s id
mon: k8s monitor ip(10.0.0.1:6789)
```
