---
title: "Testing Tools"
date: 2024-02-01
author: "sacredartr"
description: "Tools for Testing"
tags: ["tools"]
categories: ["tools"]
series: ["Tools"]
aliases: ["testing-tools"]
ShowToc: true
TocOpen: true
---

## bandit
```console
pip3 install bandit
bandit -r project
```

## sonarqube
[sonarqube](https://github.com/sacredartr/sacredartr.github.io/tree/master/config-yaml/sonarqube)
```console
mkdir -pv /usr/app/sonar/postgresql
mkdir -pv /usr/app/sonar/data
mkdir -pv /usr/app/sonar/extensions
mkdir -pv /usr/app/sonar/conf
chomd 777 /usr/app/sonar/postgresql
chomd 777 /usr/app/sonar/data
chomd 777 /usr/app/sonar/extensions
chomd 777 /usr/app/sonar/conf
kubectl apply -f pgo.yaml -n sonarqube
kubectl apply -f sonarqube.yaml -n sonarqube
```

## sonar-scanner
```console
download: https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/
export PATH="$PATH:/root/sonar-scanner/bin"
conf: sonar-project.properties
start: sonar-scanner
```