---
title: "Prow Deploy"
date: 2023-03-09
author: "sacredartr"
description: "prow deploy"
tags: ["prow"]
categories: ["prow", "deploy"]
series: ["prow Deploy"]
aliases: ["prow-deploy"]
ShowToc: true
TocOpen: true
---

# Prow Deploy

## prepare
```
kubernetes cluster
github organization + app + webhook
```
## user
```shell
kubectl create clusterrolebinding cluster-admin-binding-"${USER}" --clusterrole=cluster-admin --user="${USER}"
```
## secret
```shell
openssl rand -hex 20 > /path/to/hook/secret
kubectl create secret -n prow generic hmac-token --from-file=hmac=/path/to/hook/secret
kubectl create secret -n prow generic github-token --from-file=cert=/path/to/github/cert --from-literal=appid=<<The ID of your app>>
```

## deploy
```shell
kubectl apply -f config-yaml/prow-deploy.yaml
```

## set config
```
edit and install app at organization
add webhook at github organization/pro
```

## update
```shell
update-config:
	kubectl -n prow create configmap config --from-file=config.yaml=config.yaml --dry-run -o yaml | kubectl -n prow replace configmap config -f -

update-plugins:
	kubectl -n prow create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl -n prow replace configmap plugins -f -

update-label-config:
	kubectl -n test-pods create configmap label-config --from-file=labels.yaml=labels.yaml --dry-run -o yaml | kubectl -n test-pods replace configmap label-config -f -
```

