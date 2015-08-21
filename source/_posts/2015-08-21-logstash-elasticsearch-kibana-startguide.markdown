---
layout: post
title: "logstash elasticsearch kibana日志采集查询系统搭建"
date: 2015-08-21 14:42:30 +0800
comments: true
categories: [tools]
---

## 软件版本

```
[root@master opt]# ll
total 20
drwxr-xr-x 7 root root 4096 Aug 21 01:23 elasticsearch-1.7.1
drwxr-xr-x 8 uucp  143 4096 Mar 18  2014 jdk1.8.0_05
drwxrwxr-x 7 1000 1000 4096 Aug 21 01:09 kibana-4.1.1-linux-x64
drwxr-xr-x 5 root root 4096 Aug 21 05:58 logstash-1.5.3
drwxrwxr-x 6 root root 4096 Aug 21 06:44 redis-3.0.3
```

## 安装运行脚本

```
# java
vi /etc/profile
source /etc/profile

cd /opt/elasticsearch-1.7.1
bin/elasticsearch -p elasticsearch.pid -d

curl localhost:9200/_cluster/nodes/172.17.0.4

cd /opt/kibana-4.1.1-linux-x64/
bin/kibana 
# http://master:5601

cd /opt/redis-3.0.3
yum install gcc
yum install bzip2
make MALLOC=jemalloc

nohup src/redis-server & 

cd /opt/logstash-1.5.3/
vi index.conf
vi agent.conf

# agent可不加
bin/logstash agent -f agent.conf &
bin/logstash agent -f index.conf &
```

## logstash配置

由于程序都运行在一台机器(localhost)，redis、elasticsearch和kibana都使用默认配置。下面贴的是logstash的采集和过滤的配置：

```
[root@master logstash-1.5.3]# cat agent.conf 
input {
  file {
    path => "/var/log/yum.log"
    start_position => beginning
  }
}

output {
  redis {
    key => "logstash.redis"
    data_type => list
  }
  
  # 便于查看调试
  stdout { }
}

[root@master logstash-1.5.3]# cat index.conf 
input {
  redis {
    data_type => list
    key => "logstash.redis"
  }
}

output {
  elasticsearch {
    host => "localhost"
  }
}
```

注意要改动下采集的文件！！然后启动相应的程序，打开浏览器<http://master:5601>配置一下索引项，就可以查看了。

至于input/output/filter(map,reduce)怎么配置，查看官方文档[filter-plugins](https://www.elastic.co/guide/en/logstash/current/filter-plugins.html)

## 参考

* <http://www.cnblogs.com/buzzlight/p/logstash_elasticsearch_kibana_log.html>
* <http://www.cnblogs.com/ibook360/archive/2013/03/15/2961428.html>
* <https://www.elastic.co/guide/en/logstash/current/index.html>
* <https://www.elastic.co/guide/en/logstash/current/first-event.html>
* <https://www.elastic.co/guide/en/logstash/current/advanced-pipeline.html>
* <https://www.elastic.co/guide/en/logstash/current/codec-plugins.html>
