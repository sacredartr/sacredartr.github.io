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
