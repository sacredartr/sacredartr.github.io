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

## 文件清空
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

## 执行命令忽略报错信息
```console
unalias cp 2>/dev/null || true
```

## 文件追加内容
```console
echo 'content' >> file
```