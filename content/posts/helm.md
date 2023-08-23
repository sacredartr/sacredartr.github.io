---
title: "helm"
date: 2023-08-23
author: "sacredartr"
description: "helm"
tags: ["helm"]
categories: ["helm"]
series: ["helm"]
aliases: ["helm"]
ShowToc: true
TocOpen: true
---


# Helm Daily Tips

## helm deploy
```shell
helm upgrade --install demo demo/ -n caas --values ./values.yaml --timeout 20m 
```

## helm uninstall
```shell
helm list -n caas
helm uninstall demo -n caas
```

## helm debug
```shell
helm dependency update
helm upgrade --install demo demo/ -n caas --values ./values.yaml --timeout 20m --dry-run --debug
helm package demo
```