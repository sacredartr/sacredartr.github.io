---
title: "keepalived"
date: 2023-04-26
author: "sacredartr"
description: "keepalived"
tags: ["keepalived"]
categories: ["keepalived"]
series: ["keepalived"]
aliases: ["keepalived"]
ShowToc: true
TocOpen: true
---

# install keepalived
```shell
yum install -y keepalived
```

# set keepalived.conf
```yaml
global_defs {
   router_id hostname # 标识本节点的字符串，设置为hostname即可
}

# 定义脚本来检测服务健康状况
vrrp_script check_run {
    script "/etc/keepalived/scripts/check.sh"
    interval 5 # 每5秒检测一次
    rise 3 # 连续成功3次才算成功
    fall 2 # 连续失败2次才算失败
    #weight -20 # 不配置权重值，检测失败就进入故障状态
}

vrrp_instance VI_1 {
    state BACKUP        # 节点状态，中心节点为 MASTER，协同节点为 BACKUP
    interface eth0        # VIP绑定的网卡接口
    nopreempt   # 设置非抢占模式
    virtual_router_id 51        # 虚拟路由id，和备节点保持一致
    priority 100        # 优先级，中心节点为 100，协同节点1 为 99，协同节点 2 为 98
    mcast_src_ip 10.0.0.149        # 本机IP地址
    advert_int 1        # MASTER和BACKUP节点之间的同步检查时间间隔，单位为秒
    authentication {        # 验证类型和验证密码
        auth_type PASS        # PAAS（默认），HA
        auth_pass 1111        # MASTER和BACKUP使用相同明文才可以互通
    }
    #  virtual_ipaddress {
    #     vips
    # }
    track_script { #执行检测的脚本
        check_run
    }
    # 切换到 MASTER 时启动服务，切换到其他状态都停止服务
    notify_master /etc/keepalived/scripts/start-service.sh
    notify_backup /etc/keepalived/scripts/stop-service.sh
    notify_fault /etc/keepalived/scripts/stop-service.sh
    notify_stop /etc/keepalived/scripts/stop-service.sh
}
```

# coredns
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: coredns
spec:
  selector:
    matchLabels:
      app: coredns
  template:
    metadata:
      labels:
        app: coredns
    spec:
      hostNetwork: true # 使用本地网络
      tolerations:
        # 这些容忍度设置是为了让该守护进程集在控制平面节点上运行
        # 如果你不希望自己的控制平面节点运行 Pod，可以删除它们
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
      containers:
        - name: coredns
          image: coredns/coredns:1.10.1
          args:
            - -conf
            - /etc/coredns/Corefile
          resources:
            limits:
              memory: 170Mi
            requests:
              cpu: 10m
              memory: 70Mi
          volumeMounts:
            - name: conf
              mountPath: /etc/coredns
              readOnly: true
          ports:
            - containerPort: 53
              name: dns
              protocol: UDP
            - containerPort: 53
              name: dns-tcp
              protocol: TCP
            - containerPort: 9153
              name: metrics
              protocol: TCP
      terminationGracePeriodSeconds: 30
      volumes:
        - name: conf
          configMap:
            name: coredns
            items:
              - key: Corefile
                path: Corefile

---

apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        reload
        loadbalance
        hosts {
          10.0.0.149 control.io  # 每个节点分别配置成自己的 IP
          10.0.0.149 navigate.io # 每个节点分别配置成自己的 IP
          10.0.0.149 videomix.io # 每个节点分别配置成自己的 IP
          10.0.0.149 wdadmin.io # 每个节点分别配置成自己的 IP
          fallthrough
        }
        forward . 114.114.114.114
    }
kind: ConfigMap
metadata:
  name: coredns
```


# start-service
```shell
#!/bin/bash
set -x

# 使用 kubectl 启动 coredns 以及调度服务
# 注意：需要手动指定 --kubeconfig 参数，keepalived 里执行不会去拿默认的 kubeconfig
(
# 替换为当前集群内 kube-dns 的 clusterIP
kubeDNS=10.96.0.10
# 删除 iptables 规则，允许外部访问本机 coredns
# 因为 iptables 规则可以重复添加多次，因此 使用 while 循环，保证删除干净
rule_tcp=1
while [ "${rule_tcp}" == 1 ]
do
  if  iptables -C INPUT -p tcp --dport 53 ! -d ${kubeDNS} -j DROP
  then # 进入 then 表示退出码为 0，说明规则已经存在了，需要移除
      echo "tcp规则存在"
      iptables -D INPUT -p tcp --dport 53 ! -d ${kubeDNS} -j DROP
  else # else 则表示退出码不为 0，规则不存在,不需要移除
      echo "tcp规则已移除"
      rule_tcp=0
  fi
done

rule_udp=1
while [ "${rule_udp}" == 1 ]
do
  if  iptables -C INPUT -p udp --dport 53 ! -d ${kubeDNS} -j DROP
  then # 进入 then 表示退出码为 0，说明规则已经存在了，需要移除
      echo "tcp规则存在"
      iptables -D INPUT -p udp --dport 53 ! -d ${kubeDNS} -j DROP
  else # else 则表示退出码不为 0，规则不存在,不需要移除
      echo "udp规则已移除"
      rule_udp=0
  fi
done

basepath='/etc/keepalived/deploy'
schedulerNs='default'
# 启动业务
kubectl --kubeconfig /root/.kube/config -n ${schedulerNs} delete -f ${basepath}/deploy.yaml
kubectl --kubeconfig /root/.kube/config -n ${schedulerNs} apply -f ${basepath}/deploy.yaml
) >>/tmp/start-service.log 2>&1
```