---
layout: post
title: "kafka快速入门"
date: 2015-01-08 22:02:21 +0800
comments: true
categories: [kafka]
---

年前的时刻就听过kafka的大名，但是一直没有机会亲手尝试。数据写入HDFS然后再MapReduce去处理数据，这样会多出很多中间过程，浪费系统资源。实践下kafka+spark分析是否会更高效。首先了解kafka的基本操作。

[文档](http://kafka.apache.org/documentation.html)先进行简单的介绍。kafka是一个分布式的、分区的、冗余的日志服务，提供消息系统类似的功能。主要的概念： Topic，Producers，Consumers，Partition，Distribution（replicated）；producers通过TCP发送消息给Kafka集群，然后consumer从Kafka集群获取信息。

Kafka遵循：

* 对于同一个生产者产生的消息有序。
* 消费者看到的消息顺序和消息存储的顺序一致
* 一个主题冗余为N的，可以容忍N-1个服务器失败而不会丢失任何消息。

下载[kafka](http://kafka.apache.org/downloads.html)，当前稳定版本为[kafka_2.10-0.8.1.1](https://archive.apache.org/dist/kafka/0.8.1.1/RELEASE_NOTES.html)。下载后解压就可以运行了。

## 启动单实例

由于windows运行的程序放在`bin\windows`下面。需要对kafka-run-class.bat批处理文件进行稍稍修改：

```
rem set BASE_DIR=%CD%\..
set BASE_DIR=%CD%\..\..

rem for %%i in (%BASE_DIR%\core\lib\*.jar) do (
for %%i in (%BASE_DIR%\libs\*.jar) do (
```

运行程序：

```
bin\windows>zookeeper-server-start.bat ..\..\config\zookeeper.properties

rem 再打开一个cmd窗口运行
bin\windows>kafka-server-start.bat ..\..\config\server.properties

```

整合成一个脚本`start-all.bat`，方便以后使用：

```
start zookeeper-server-start.bat ..\..\config\zookeeper.properties
timeout 5
start kafka-server-start.bat ..\..\config\server.properties
exit
```

## Topic

```
bin\windows>kafka-run-class.bat kafka.admin.TopicCommand --create --zookeeper localhost:2181 --replication 1 --partitions 1 --topic hello
Created topic "hello".

bin\windows>kafka-run-class.bat kafka.admin.TopicCommand --list --zookeeper localhost:2181
hello

bin\windows>kafka-run-class.bat kafka.admin.TopicCommand  --describe --zookeeper localhost:2181 --topic hello
Topic:hello     PartitionCount:1        ReplicationFactor:1     Configs:
        Topic: hello    Partition: 0    Leader: 0       Replicas: 0     Isr: 0
```

如果是在linux下，可以运行kafka-topics.sh来创建和查询。如果觉得打印的日志很不爽，可以修改config目录下的log4j.properties（在脚本中通过环境变量log4j.configuration指定为该文件）。

## 发送接受消息

```
rem 生产者
bin\windows>kafka-console-producer.bat --broker-list localhost:9092 --topic hello

rem 消费者（新开一个窗口）
bin\windows>kafka-console-consumer.bat --zookeeper localhost:2181 --topic hello --from-beginning
```

都启动后，在producer的窗口输入信息。同一时刻，consumer也会打印输入的内容。

这个两个命令都有很多参数，直接输入命令不加任何参数可以输出帮助，了解各个参数的含义及其用法。

## Kafka集群

集群的配置和zookeeper的集群配置方式很类似。只要修改broker.id和数据存储目录即可。

拷贝server.properties，然后修改下面的三个属性：

```
broker.id=1
port=9192
log.dir=/tmp/kafka-logs-1
```

然后启动：

```
set JMX_PORT=19999
start kafka-server-start.bat ..\..\config\server-1.properties
set JMX_PORT=29999
start kafka-server-start.bat ..\..\config\server-2.properties
set JMX_PORT=39999
start kafka-server-start.bat ..\..\config\server-3.properties
```

创建Topic

```
bin\windows>kafka-run-class.bat kafka.admin.TopicCommand --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic mhello
Created topic "mhello".

bin\windows>kafka-run-class.bat kafka.admin.TopicCommand --describe --zookeeper localhost:2181 --topic mhello
Topic:mhello    PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: mhello   Partition: 0    Leader: 0       Replicas: 0,3,1 Isr: 0,3,1

bin\windows>kafka-console-producer.bat --broker-list localhost:9092 --topic mhello
bin\windows>kafka-console-consumer.bat --zookeeper localhost:2181 --topic mhello --from-beginning
		
```

描述命令的第一行是所有分区的概要信息，接下来的每一行是每一个分区的信息。Leader后面的数字表示对应的broker-id的进程为当前分区的主节点，后面的Replicas是数据分布的情况（不管数据存在与否），Isr是当前存活的节点的数据分布情况。

把刚刚启动的1，2，3的节点都停掉，再查描述信息。

```
bin\windows>kafka-run-class.bat kafka.admin.TopicCommand --describe --zookeeper localhost:2181 --topic mhello
Topic:mhello    PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: mhello   Partition: 0    Leader: 0       Replicas: 0,3,1 Isr: 0

bin\windows>kafka-console-consumer.bat --zookeeper localhost:2181 --topic mhello --from-beginning
hello1
hello2
hello3		
```

只要有一个节点存在，获取数据都没有问题。如果全部停了，就不能提供服务，但是查询describe命令，显示的还是0，囧！！

开启1，2，3节点后，mhello分区的状态：

```
Topic:mhello    PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: mhello   Partition: 0    Leader: 3       Replicas: 0,3,1 Isr: 3,1
```

问题：当broker-id修改后，原来的数据，并不能透明的过渡。把broker-id为0的节点修改为1000，然后重启。mhello的数据仍然找不到。再次改回0，存活节点才都回来。

```
        Topic: mhello   Partition: 0    Leader: 3       Replicas: 0,3,1 Isr: 3,1,0
```

## 小结

把基本的功能操作了一遍，都是使用命令行操作，接下来学习下和[hadoop结合](https://github.com/linkedin/camus/)，使用java-api来操作Kafka。

## 参考

* [kafka gettingStarted](http://kafka.apache.org/documentation.html#gettingStarted)
