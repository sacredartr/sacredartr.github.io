---
title: "Docker Daily Tips"
date: 2022-08-16
author: "sacredartr"
description: "Docker tips for daily use"
tags: ["docker"]
categories: ["docker", "tips"]
series: ["Docker Tips"]
aliases: ["docker-daily-tips"]
ShowToc: true
TocOpen: true
---

# Docker Daily Tips

## clear all containers
```console
docker stop $(docker ps -q) && docker rm $(docker ps -aq)
```

## docker pull:error response from daemon
```
yum install bind-utils
dig @114.114.114.114 registry-1.docker.io
echo "54.175.43.85    registry-1.docker.io" >> /etc/hosts
```

## clear specified containers
```console
docker stop $(docker ps -a|grep hours|awk '{print $1}') && docker rm $(docker ps -a|grep hours|awk '{print $1}')
```

## create docker https registry
```console
mkdir -p /opt/docker/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /opt/docker/registry/certs/domain.key -x509 -days 365 -out /opt/docker/registry/certs/domain.crt
docker run -d --name registry2 -p 5000:5000 -v /opt/docker/registry/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key registry:2
```

## use docker https registry
```console
scp /opt/docker/registry/certs/domain.crt /etc/docker/certs.d/registry.docker.com:5000/ca.crt
docker pull busybox:latest
docker tag busybox registry.docker.com:5000/busybox:latest
docker push registry.docker.com:5000/busybox:latest
curl -X GET https://registry.docker.com:5000/v2/_catalog -k
```