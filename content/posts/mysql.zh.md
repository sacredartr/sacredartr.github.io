---
title: "Mysql"
date: 2022-08-16
author: "sacredartr"
description: "mysql"
tags: ["mysql"]
categories: ["mysql"]
series: ["Mysql"]
aliases: ["mysql"]
ShowToc: true
TocOpen: true
---

# Mysql

## 数据库命令

* 获取所有表名
```sql
select `table_name` from information_schema.tables where `table_schema` = '{}'
```

* 获取所有列名
```sql
select `column_name` from information_schema.columns where `table_name`='{}' and `table_schema` = '{}'
```

*获取所有库名
```sql
select schema_name as `database` from information_schema.schemata
```

*获取表中所有主键
```sql
select k.column_name from information_schema.table_constraints t join information_schema.key_column_usage k 
                using (constraint_name,table_schema,table_name) where t.constraint_type='PRIMARY KEY' and t.table_schema='{}' and t.table_name='{}'
```

* 创建视图
```sql
create view {} as select {} from {}
```

* 导出数据
```console
mysqldump -uroot -p database table1 table2 > target.sql
```
--skip-opt 不锁表
-d 表示 只导出结构

* 导入数据
```console
mysql -uroot -p database < target.sql
```

* 备份恢复
```console
xbstream -x -C /data < ./target.xb
xtrabackup --decompress --target-dir=/data
xtrabackup --prepare  --target-dir=/data
chown -R mysql:mysql /data
mysqld_safe --defaults-file=/data/backup-my.cnf --user=mysql --datadir=/data &
```  

* binlog
```console
mysqlbinlog --base64-output=decode-rows  --verbose file | grep -i   -A 100 delete 
```

## dts
```python
import re
import json
import subprocess
import pandas as pd
from kafka import KafkaProducer
from utils.db_config import base_backup
from tencentcloud.common import credential
from CKafka.Dts.dts_config import get_redis
from CKafka.ckafka_config import bootstrap_servers
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.cdb.v20170320 import cdb_client, models

class DataSyncDts():

    def __init__(self):
        self.redis_client = get_redis()
        self.key = "dts_file_name"
        self.base_topic = "base.row_delete.topic"
        self.base_finance_new_topic = "base_finance_new.row_delete.topic"
        self.base_factor_topic = "base_finance_new.row_delete.topic"

    def init_data(self):
        print("数据初始化...构建数据库字典")
        self.database = {}
        sql = """select schema_name as `database` from information_schema.schemata"""
        database = pd.read_sql(sql, base_backup())
        for i, row in database.iterrows():
            if row['database'] not in ["base", "base_finance_new"]:
                continue
            sql = """select `table_name` from information_schema.tables where `table_schema` = '{}'""".format(
                row['database'])
            table = pd.read_sql(sql, base_backup())
            table_column = {}
            for j, row_j in table.iterrows():
                sql = """select k.column_name from information_schema.table_constraints t join information_schema.key_column_usage k 
                  using (constraint_name,table_schema,table_name) where t.constraint_type='PRIMARY KEY' and t.table_schema='{}' and t.table_name='{}'""".format(
                    row["database"], row_j["table_name"])
                key_column = pd.read_sql(sql, base_backup())
                sql = """select `column_name` from information_schema.columns where `table_name`='{}' and `table_schema` = '{}'""".format(
                    row_j["table_name"], row["database"])
                column = pd.read_sql(sql, base_backup())
                index_key_column = []
                for k, row_k in key_column.iterrows():
                    index = column["column_name"].values.tolist().index(row_k["column_name"])
                    index_key_column.append((index, row_k["column_name"]))
                index = None
                try:
                    index = column["column_name"].values.tolist().index('update_time')
                except Exception as e:
                    pass
                if index:
                    index_key_column.append((index, 'update_time'))
                table_column[row_j["table_name"]] = index_key_column

            self.database[row["database"]] = table_column

    def download(self):
        try:
            cred = credential.Credential("******", "******")
            httpProfile = HttpProfile()
            httpProfile.endpoint = "cdb.tencentcloudapi.com"

            clientProfile = ClientProfile()
            clientProfile.httpProfile = httpProfile
            client = cdb_client.CdbClient(cred, "ap-shanghai", clientProfile)

            req = models.DescribeBinlogsRequest()
            params = {
                "InstanceId": "cdb-2mvrb173"
            }
            req.from_json_string(json.dumps(params))
            resp = client.DescribeBinlogs(req)
            returned = json.loads(resp.to_json_string())
            url = returned['Items'][0]['IntranetUrl']
            file_name = returned['Items'][0]['Name']
            self.file_name = "/home/{}".format(file_name)
            dts_file_name = self.redis_client.get(self.key).decode('utf-8')
            print(dts_file_name)
            if dts_file_name == file_name:
                base_backup().execute('flush logs')
                return False
            p = subprocess.Popen("wget -c '{}' -O /home/{}".format(url, file_name), shell=True,
                                 stdout=subprocess.PIPE)
            p.wait()
            self.redis_client.set(self.key, file_name)
            return True

        except TencentCloudSDKException as err:
            print(err)
            return False

    def parse(self):
        producer = KafkaProducer(bootstrap_servers=bootstrap_servers,
                                 max_block_ms=60 * 1000)
        status, ret = subprocess.getstatusoutput(
            '/usr/src/app/CKafka/Dts/mysqlbinlog --base64-output=decode-rows  --verbose {} | grep -i   -A 300 delete'.format(self.file_name))
        res = ret.replace('#','')
        res = res.replace('\n','')
        row_sql = re.findall("(DELETE\sFROM.*?)(at\s\d+|DELETE)", res)
        for row in row_sql:
            try:
                database = re.findall("DELETE\sFROM\s(.*?)\..*?\sWHERE", row[0])
                table = re.findall("DELETE\sFROM\s.*?\.(.*?)\sWHERE", row[0])
                value = re.findall("@\d+=(.*?)\s\s", row[0])
                last_value = re.findall("@{}=(.*?)\s$".format(str(len(value) + 1)), row[0])
                value += last_value
                database = database[0].replace("`","")
                table = table[0].replace("`","")
                res = {}
                if database in ["base", "base_finance_new"]:
                    for i, row in enumerate(self.database[database][table]):
                        res[row[1].replace("\'","")] = value[row[0]].replace("\'","")
                    res["Operation"] = "delete"
                    res["DbName"] = database
                    res["TableName"] = table
                    res = json.dumps(res)
                    data = bytes('{}'.format(res),'utf-8')
                    print(data)
                    if database == "base":
                        producer.send(self.base_topic, value=data)
                    elif database == "base_finance_new":
                        producer.send(self.base_finance_new_topic, value=data)
                    producer.flush()
            except Exception as e:
                print(e)

if __name__ == '__main__':
    dts = DataSyncDts()
    if dts.download():
        dts.init_data()
        dts.parse()
    else:
        print("最新binlog已解析，正在刷新binlog...")
```