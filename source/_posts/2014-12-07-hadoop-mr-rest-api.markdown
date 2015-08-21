---
layout: post
title: "Hadoop查看作业状态Rest接口"
date: 2014-12-07 10:09:49 +0800
comments: true
categories: [hadoop]
---

hadoop yarn提供了web端查看任务状态，同时可以通过rest的方式获取任务的相关信息。rest接口和网页端的每个界面一一对应。

![](http://file.bmob.cn/M00/D7/C0/oYYBAFSDxeaARA6AAAenwsLMShM027.png)

上面的5个图的链接为：

```
http://hadoop-master1:8088/cluster/apps/RUNNING
http://hadoop-master1:8088/cluster/app/application_1417676507722_1846
http://hadoop-master1:8088/proxy/application_1417676507722_1846/
http://hadoop-master1:8088/proxy/application_1417676507722_1846/mapreduce/job/job_1417676507722_1846
http://hadoop-master1:19888/jobhistory/job/job_1417676507722_1846/mapreduce/job/job_1417676507722_1846
```

## 查看正在运行的任务

```
curl http://hadoop-master1:8088/ws/v1/cluster/apps?states=RUNNING
...

curl http://hadoop-master1:8088/proxy/application_1417676507722_1867/ws/v1/mapreduce/info
...
curl http://hadoop-master1:8088/proxy/application_1417676507722_1867/ws/v1/mapreduce/jobs
...

curl http://hadoop-master1:8088/proxy/application_1417676507722_1867/ws/v1/mapreduce/jobs/job_1417676507722_1867
...
curl http://hadoop-master1:8088/proxy/application_1417676507722_1867/ws/v1/mapreduce/jobs/job_1417676507722_1867/counters
...
curl http://hadoop-master1:8088/proxy/application_1417676507722_1867/ws/v1/mapreduce/jobs/job_1417676507722_1867/conf

```

如果上面的任务是已经完成的，获取对应的信息时返回的值是空的。

```
curl http://hadoop-master1:8088/proxy/application_1417676507722_1867/ws/v1/mapreduce/jobs/job_1417676507722_1867/counters
```

## 查看执行完成的任务

```
curl http://hadoop-master1:19888/ws/v1/history
curl http://hadoop-master1:19888/ws/v1/history/info
...
curl http://hadoop-master1:19888/ws/v1/history/mapreduce/jobs?startedTimeBegin=$(date +%s -d '-1 hour')000
...
curl http://hadoop-master1:19888/ws/v1/history/mapreduce/jobs/job_1417676507722_1867
curl http://hadoop-master1:19888/ws/v1/history/mapreduce/jobs/job_1417676507722_1867/counters
curl http://hadoop-master1:19888/ws/v1/history/mapreduce/jobs/job_1417676507722_1867/conf

curl -H "Accept: application/xml" "http://hadoop-master1:8088/ws/v1/cluster/apps?states=FINISHED&limit=1" | xmllint --format - 
```

后面的参数和运行任务一致，只是提供服务不同。

## xml转csv

![](http://file.bmob.cn/M00/D7/D5/oYYBAFSEHuKAaAgHAACb9_KkMEU331.png)

```
$ curl -H "Accept: application/xml" "http://hadoop-master1:8088/ws/v1/cluster/apps?startedTimeBegin=$(date +%s -d '-1 hour')000" 2>/dev/null | xsltproc yarn.xslt -  | sort -r

application_1417676507722_1973,AccessLogOnlyHiveJob,RUNNING,UNDEFINED,1417942144941,0,19416
application_1417676507722_1972,InfoSecurityLogJob,FINISHED,SUCCEEDED,1417942084278,1417942098184,13906
application_1417676507722_1971,InfoSecurityLogJob,FINISHED,SUCCEEDED,1417941603456,1417941617773,14317
application_1417676507722_1970,AccessLogOnlyHiveJob,FINISHED,SUCCEEDED,1417941581080,1417942142287,561207
application_1417676507722_1969,InfoSecurityLogJob,FINISHED,SUCCEEDED,1417941422664,1417941436456,13792
```

## 参考

* [Hadoop YARN - Introduction to the web services REST API's.](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html)
* [ResourceManager REST API's.](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/ResourceManagerRest.html)
* [MapReduce Application Master REST API's.](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/MapredAppMasterRest.html)
* [History Server REST API's.](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/HistoryServerRest.html)
* [Hadoop YARN中web服务的REST API介绍](http://blog.csdn.net/wypblog/article/details/21159795)