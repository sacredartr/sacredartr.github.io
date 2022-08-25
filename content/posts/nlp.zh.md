---
title: "NLP"
date: 2022-08-18
author: "sacredartr"
description: "nlp"
tags: ["nlp"]
categories: ["nlp"]
series: ["NLP"]
aliases: ["nlp"]
ShowToc: true
TocOpen: true
---

# 词频统计
```python
# encoding: utf-8
import jieba
import pandas as pd
import datetime as dt


class wordCount():
    def __init__(self):
        self.pre_data()

    def pre_data(self):
        jieba.load_userdict('./dict.txt')
        stopwords = pd.read_table('./stop.txt')
        self.stop_list = stopwords["stop_word"].tolist()
        self.stop_list.append("\n")

    def run(self, year, month):
        start = dt.date(year, month, 1)
        if month == 6:
            end = dt.date(year, month, 30)
        else:
            end = dt.date(year, month, 31)
        sql = """select fund_id, report_date, outlook as sentence from manager_viewpoint where report_date 
        between '{}' and '{}'""".format(dt.datetime.strftime(start, '%Y-%m-%d'), dt.datetime.strftime(end, '%Y-%m-%d'))
        df = pd.DataFrame()
        df['token'] = df['sentence'].apply(lambda x: [i for i in list(jieba.cut(x)) if i not in self.stop_list])

        words = []

        for content in df['token']:
            words.extend(content)

        corpus = pd.DataFrame(words, columns=['word'])
        corpus['count'] = 1

        group = corpus.groupby('word')["count"].count().sort_values(ascending=False).reset_index()
        group["statistic_date"] = end
        print(group.tail(1))

if __name__ == '__main__':
    word_count = wordCount()
    for year in [2021]:
        word_count.run(year, 6)
```