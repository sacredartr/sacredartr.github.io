---
title: "tekton"
date: 2024-06-25
author: "sacredartr"
description: "tekton"
tags: ["tekton"]
categories: ["tekton"]
series: ["tekton"]
aliases: ["tekton"]
ShowToc: true
TocOpen: true
---

# Tekton

## Deploy
[tekton](https://github.com/sacredartr/sacredartr.github.io/tree/master/config-yaml/tekton)
```console
# kubectl version
# ... GitVersion:"v1.23.6" ...
kubectl apply -f TektonCD-Pipelines.yaml
curl -Ls https://github.com/tektoncd/pipeline/releases/download/v0.44.4/release.yaml -o TektonCD-Pipelines.yaml
curl -ls https://storage.googleapis.com/tekton-releases/triggers/previous/v0.22.2/release.yaml -o TektonCD-Triggers.yaml
curl -ls https://storage.googleapis.com/tekton-releases/triggers/previous/v0.22.2/interceptors.yaml -o TektonCD-Triggers-interceptors.yaml
kubectl apply -f TektonCD-Triggers.yaml
kubectl apply -f TektonCD-Triggers-interceptors.yaml
curl -ls https://storage.googleapis.com/tekton-releases/dashboard/previous/v0.35.1/release-full.yaml -o TektonCD-Dashboard-full.yaml
kubectl apply -f TektonCD-Dashboard-full.yaml
```

## Use
[tekton](https://github.com/sacredartr/sacredartr.github.io/tree/master/config-yaml/tekton)
```console
kubectl create ns demo
# pipeline
kubectl apply -f tekton/demo-pipeline.yaml -n demo
# pipeline Ref task
kubectl apply -f tekton/demo-clustertask.yaml
# ssh secret 
kubectl apply -f tekton/demo-secret.yaml -n demo
# pipelinerun
kubectl apply -f tekton/demo-pipelinerun.yaml -n demo
...
tekton/*
```