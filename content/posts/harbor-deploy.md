---
title: "Harbor Deploy"
date: 2023-02-17 
author: "sacredartr"
description: "harbor deploy"
tags: ["harbor"]
categories: ["harbor", "deploy"]
series: ["Harbor Deploy"]
aliases: ["harbor-deploy"]
ShowToc: true
TocOpen: true
---

# Harbor Deploy

## prepare
[harbor](https://github.com/sacredartr/sacredartr.github.io/tree/master/config-yaml/harbor)
[artifacthub](https://artifacthub.io/)
```
kubernetes cluster
helm
crictl
harbor.tar.xz
redis.tar.xz
pgo.tar.xz
```

## deploy pgo-ha
```shell
# ctr -n k8s.io image import all pakage
cd chart
# created pgo namespace
kubectl create ns pgo
# install pgo controller CRD
helm install -n pgo pgo .
# check pod
kubectl -n pgo get pod
NAME                           READY   STATUS    RESTARTS   AGE
pgo-694f6b79bc-gpw2h           1/1     Running   0          16s
pgo-694f6b79bc-lw9pl           1/1     Running   0          16s
pgo-upgrade-76fdb74df8-ldzcr   1/1     Running   0          16s
pgo-upgrade-76fdb74df8-zqrft   1/1     Running   0          16s
# install ha-postgres
kubectl create ns postgres
kubectl -n postgres apply -f ha-postgres.yaml
# check pod
kubectl -n postgres get pod 
NAME                                READY   STATUS      RESTARTS   AGE
harbor-backup-c6tq-kzxd5            0/1     Completed   0          5m26s
harbor-harbor-ha-instance-8ncb-0    4/4     Running     0          6m16s
harbor-harbor-ha-instance-v8np-0    4/4     Running     0          6m16s
harbor-pgbouncer-58d57f45d6-82skz   2/2     Running     0          6m15s
harbor-pgbouncer-58d57f45d6-rks94   2/2     Running     0          6m15s
harbor-repo-host-0                  2/2     Running     0          6m16s
# get secret
kubectl -n postgres get secret harbor-pguser-harbor -o=jsonpath='{@.data.password}' | base64 -d
# get host
kubectl -n postgres get secret harbor-pguser-harbor -o=jsonpath='{@.data.host}' | base64 -d
```

## deploy redis-ha
```shell
# ctr -n k8s.io image import all pakage
cd chart
# create redis namespace
kubectl create ns redis
# install redis
helm install -n redis redis .
# check pod 
kubectl -n redis get pod 
NAME                      READY   STATUS    RESTARTS   AGE
redis-redis-ha-server-0   3/3     Running   0          25s
pgo-upgrade-76fdb74df8-zqrft   1/1     Running   0          16s
# domain
redis+sentienl redis-redis-ha.redis.svc.cluster.local
k8s-haproxy redis-redis-ha-haproxy.redis.svc.cluster.local
```

## deploy harbor-ha
```shell
# ctr -n k8s.io image import all pakage
cd chart
# create namespace
kubectl create ns harbor
# install harbor
helm install -n harbor harbor .
# check pod
kubectl -n harbor get pod 
NAME                                 READY   STATUS    RESTARTS   AGE
harbor-core-6cb79d76-zcjwn           1/1     Running   0          3m44s
harbor-jobservice-6b8bd7d6d9-7247v   1/1     Running   0          3m44s
harbor-nginx-7756ccb484-n7vpb        1/1     Running   0          3m44s
harbor-portal-57cf48cfc8-7b6tq       1/1     Running   0          10m
harbor-registry-cccdf8f69-m8cws      2/2     Running   0          3m44s
```
