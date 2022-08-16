---
title: "Linux Daily Tips"
date: 2022-08-16
author: "sacredartr"
description: "Linux tips for daily use"
tags: ["linux"]
categories: ["linux", "tips"]
series: ["Linux Tips"]
aliases: ["linux-daily-tips"]
ShowToc: true
TocOpen: true
---

# Linux Daily Tips

## clear file
```console
cat /dev/null > file
```

## xargs 
```console
ls ./* | xargs -i cp {} /tmp/
```

## sed
```console
sed -i 's/password: .*/password: 123456/g' file
```

## awk
```console
cat file | awk '$1 ~ /th/ {print $1}'
```

## ignore error message
```console
unalias cp 2>/dev/null || true
```

## file append content
```console
echo 'content' >> file
```