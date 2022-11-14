---
title: "Python"
date: 2022-08-16
author: "sacredartr"
description: "python"
tags: ["python"]
categories: ["python"]
series: ["Python"]
aliases: ["python"]
ShowToc: true
TocOpen: true
---

# Python

## pandas常用命令

* 字符串转日期
```console
dt.datetime.strptime(x, '%Y-%m-%d').date()
pd.to_datetime(x, format='%Y-%m-%d')
```

* 日期转字符串
```console
dt.datetime.strftime(x, '%Y-%m-%d')
```

* 日期相加
```console
date + dt.timedelta(days=-1)
```

* merge
```console
pd.merge(left,right,how='left',on='')
```

* apply
```console
df['x'].apply(lambda x: float(x))
```

* groupyby返回第N行
```console
df.groupby("columns").nth(N)
```

* 写入excel
```console
writer = pd.ExcelWriter("demo.xlsx")
res.to_excel(writer, sheet_name="middle", index=False, header=False)
res_final.to_excel(writer, sheet_name="final", index=False, header=False)
```

* 读取excel
```console
pd.read_excel('demo.xlsx', sheet_name='middle')
```

* explode 将每行指定columns中的list转为列
```console
df.explode("dirty", ignore_index=True)
```

* squeeze 将series压缩成一个值
```console
row.squeeze("columns")
```

* nlargest 前N个
```console
df.nlargest(5, "columns")
```

* nsmallest 后N个
```console
df.nsmallest(5, "columns")
```

*  clip 异常值监测
```console
df.clip(50, 60)
```

* ffill前向填充
```console
df['nav'].ffill()
```

* bfill后向填充
```console
df['nav'].bfill()
```

* stack
> 列旋转成行

* unstack
> 行旋转成列

* 行转列特殊实战
```console
df.set_index([df.groupby('fund_id').cumcount(), 'fund_id'])[column_name].unstack().T
```

* 只取数据下三角
```console
df.mask(np.triu(np.ones(df.shape, dtype=np.bool_)))
```

* 数字转时间
```console
time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(x))
time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(float(x/1000)))
datetime.datetime.fromtimestamp(x).strftime('%Y-%m-%d %H:%M:%S')
```

## es查询使用

* 模糊匹配
```python
from elasticsearch import Elasticsearch
es_server = Elasticsearch([{'host': '172.0.0.1', 'port': 31696}])
search_body = {
            "query": {
                "multi_match":{
                    "query":"name",
                    "fields": ["fund_name", "fund_full_name"]
                }
            },
        }
es_server.search(index='private_fund_info_list3', body=search_body)
```

* 精确匹配
```python
from elasticsearch import Elasticsearch
es_server = Elasticsearch([{'host': '172.0.0.1', 'port': 31696}])
search_body = {
            "query": {
                "multi_match":{
                    "query":"name",
                    "type":"phrase_prefix",
                    "fields": ["fund_name", "fund_full_name"]
                }
            },
        }
es_server.search(index='private_fund_info_list3', body=search_body)
```

* and与or查询
```python
from elasticsearch import Elasticsearch
es_server = Elasticsearch([{'host': '172.0.0.1', 'port': 31696}])
search_body = {
	"query": {
		"bool": {
			"must": [{
				"match_phrase": {
					"name": "a"
				}
			}],
			"should": [{
				"match_phrase": {
					"city": "b"
				}
			},
			{
				"match_phrase": {
					"city": "c"
				}
			}],
		}
	},
}
es_server.search(index='private_fund_info_list3', body=search_body)
```

```python
url = 'http://172.0.0.1:31696/private_fund_info_list3/_search'
body = {
    "query": {
                "multi_match":{
                    "query":"JR307094",
                    "type":"phrase_prefix",
                    "fields": ["fund_id"]
                }
            }
}
```

* es_bulk
```python
from elasticsearch import Elasticsearch
from elasticsearch import helpers
import pandas as pd
from sqlalchemy import create_engine
INDEX_NAME = "test"
actions = []
CHUNKSIZE = 5000
INDEX_MAPPING = {
    "properties": {
        'fund_id': {"type": "keyword"},
        'fund_name': {"type": "text"},
        'fund_full_name': {"type": "text"},

    }
}

es = Elasticsearch(
    ['127.0.0.1'],
    port=9200
)

es.indices.create(index=INDEX_NAME, ignore=[400])
es.indices.put_mapping(index=INDEX_NAME, doc_type='manager', body=INDEX_MAPPING, ignore=[400])


print("Connect to mysql...")
_engine = create_engine("sm_data_calc03:N853OVcSIH06Zgm@172.0.0.1:9618", 'test')
df = pd.read_sql("""select * from table""", _engine)
for ix, row in df.iterrows():
    d = row.dropna().to_dict()

    action = {
        '_index': INDEX_NAME,
        '_type': 'manager',
        '_source': d
    }

    actions.append(action)

    if ix % CHUNKSIZE == 0:
        helpers.bulk(es, actions)
        actions.clear()
        print('sm_info_es >>> insert or update:{}, take_time:{:.2f}'.format(ix, time.time() - t2))

if len(actions):
    helpers.bulk(es, actions)
```
