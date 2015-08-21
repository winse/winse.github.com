---
layout: post
title: "编译/搭建Spark环境"
date: 2014-10-16 16:55:39 +0800
comments: true
categories: [spark]
---

2015-04更新：【后记 Spark-1.3.0】

官网提供的hadoop版本没有2.5的。这里我自己下载源码再进行编译。先下载spark-1.1.0.tgz，解压然后执行命令编译：

```
export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
mvn -Pyarn -Phadoop-2.4 -Dhadoop.version=2.5.1 -Phive -X -DskipTests clean package

# mvn package eclipse:eclipse -Phadoop-2.2 -Pyarn -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests
```

用64位的JDK！！加上maven参数，不然很可能出现OOM（甚至各种稀奇古怪的问题）。编译的时间也挺长的，可以先去吃个饭。或者取消一些功能的编译（如hive）。

编译完后，在assembly功能下会生成包括所有spark及其依赖的jar文件。

```
[root@docker scala-2.10]# cd spark-1.1.0/assembly/target/scala-2.10/
[root@docker scala-2.10]# ll -h
total 135M
-rw-r--r--. 1 root root 135M Oct 15 21:18 spark-assembly-1.1.0-hadoop2.5.1.jar
```

## 打包

上面我们已经编译好了spark程序，这里对其进行打包集成到一个压缩包。使用程序自带的make-distribution.sh即可。

为了减少重新编译的巨长的等待时间，修改下脚本`make-distribution.sh`的maven编译参数，去掉maven的clean阶段操作（最好直接注释掉mvn那行），修改最终结果如下：

```
#BUILD_COMMAND="mvn clean package -DskipTests $@"
#BUILD_COMMAND="mvn package -DskipTests $@"
```

然后执行命令：

```
[root@docker spark-1.1.0]# sh -x make-distribution.sh --tgz  --skip-java-test -Pyarn -Phadoop-2.4 -Dhadoop.version=2.5.1 -Phive 
[root@docker spark-1.1.0]# ll -h
total 185M
...
-rw-r--r--. 1 root root 185M Oct 16 00:09 spark-1.1.0-bin-2.5.1.tgz
```

最终会在目录行打包生成tgz的文件。

## 本地运行

把本机ip主机名写入到hosts，方便以后windows本机查看日志

```
[root@docker spark-1.1.0-bin-2.5.1]# echo 192.168.154.128 docker >> /etc/hosts
[root@docker spark-1.1.0-bin-2.5.1]# cat /etc/hosts
...
192.168.154.128 docker
```

### 运行helloworld：

```
[root@docker spark-1.1.0-bin-2.5.1]# bin/run-example SparkPi 10
Spark assembly has been built with Hive, including Datanucleus jars on classpath
...
14/10/16 00:22:36 INFO SparkContext: Job finished: reduce at SparkPi.scala:35, took 2.848632007 s
Pi is roughly 3.139344
14/10/16 00:22:36 INFO SparkUI: Stopped Spark web UI at http://docker:4040
...
```

### 交互式操作：

```
[root@docker spark-1.1.0-bin-2.5.1]# bin/spark-shell --master local[2]
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 1.1.0
      /_/

Using Scala version 2.10.4 (Java HotSpot(TM) 64-Bit Server VM, Java 1.7.0_60)
...
14/10/16 00:25:57 INFO SparkUI: Started SparkUI at http://docker:4040
14/10/16 00:25:57 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
14/10/16 00:25:58 INFO Executor: Using REPL class URI: http://192.168.154.128:39385
14/10/16 00:25:58 INFO AkkaUtils: Connecting to HeartbeatReceiver: akka.tcp://sparkDriver@docker:57417/user/HeartbeatReceiver
14/10/16 00:25:58 INFO SparkILoop: Created spark context..
Spark context available as sc.

scala> 

```

说明下环境，我使用windows作为开发环境，使用虚拟机中的linux作为测试环境。同时通过ssh连接的隧道来实现windows无缝的访问虚拟机linux操作系统。

启动交互式访问后，就可以通过浏览器访问4040查看spark程序的状态。

![](http://file.bmob.cn/M00/1E/4B/wKhkA1Q_3NOALefuAAEimqVy6-s418.png)

任务已经启动，接下来就可以进行操作：

```
scala> val textFile=sc.textFile("README.md")
textFile: org.apache.spark.rdd.RDD[String] = README.md MappedRDD[1] at textFile at <console>:12

scala> textFile.count()
res0: Long = 141

scala> textFile.first()
res1: String = # Apache Spark

scala> val linesWithSpark = textFile.filter(line=>line.contains("Spark"))
linesWithSpark: org.apache.spark.rdd.RDD[String] = FilteredRDD[2] at filter at <console>:14

scala> textFile.filter(line=>line.contains("Spark")).count()
res2: Long = 21

scala> textFile.map(_.split(" ").size).reduce((a,b) => if(a>b) a else b)
res3: Int = 15

scala> import java.lang.Math
import java.lang.Math

scala> textFile.map(_.split(" ").size).reduce((a,b)=>Math.max(a,b))
res4: Int = 15

scala> val wordCounts = textFile.flatMap(_.split(" ")).map((_, 1)).reduceByKey(_+_)
wordCounts: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[8] at reduceByKey at <console>:15

scala> wordCounts.collect()
res5: Array[(String, Int)] = Array((means,1), (under,2), (this,4), (Because,1), (Python,2), (agree,1), (cluster.,1), (its,1), (follows.,1), (general,2), (have,2), (YARN,,3), (pre-built,1), (locally.,1), (locally,2), (changed,1), (MRv1,,1), (several,1), (only,1), (sc.parallelize(1,1), (This,2), (learning,,1), (basic,1), (requests,1), (first,1), (Configuration,1), (MapReduce,2), (CLI,1), (graph,1), (without,1), (documentation,1), ("yarn-client",1), ([params]`.,1), (any,2), (setting,2), (application,1), (prefer,1), (SparkPi,2), (engine,1), (version,3), (file,1), (documentation,,1), (<http://spark.apache.org/>,1), (MASTER,1), (entry,1), (example,3), (are,2), (systems.,1), (params,1), (scala>,1), (provides,1), (refer,1), (MLLib,1), (Interactive,2), (artifact,1), (configure,1), (can,8), (<art...

```

执行了上面一些操作后，通过网页查看状态变化：

![](http://file.bmob.cn/M00/1E/4C/wKhkA1Q_3w6AM6njAAF-MCCYh2s170.png)

## Spark-standalone集群

部署集群需要用到多个服务器，这里我使用docker来进行部署。

本来应该早早完成本文的实践，但是在搭建docker-hadoop集群时花费了很多的时间。关于搭建集群dnsmasq处理域名问题参见下一篇文章。
最终实现可以参考：[docker-hadoop](https://github.com/winse/docker-hadoop/tree/spark-yarn)

```
[root@docker docker-hadoop]# docker run -d  --dns 172.17.42.1 --name slaver2 -h slaver1 spark-yarn
[root@docker docker-hadoop]# docker run -d  --dns 172.17.42.1 --name slaver2 -h slaver2 spark-yarn
[root@docker docker-hadoop]# docker run -d  --dns 172.17.42.1 --name master -h master spark-yarn

[root@docker docker-hadoop]# docker ps | grep spark | awk '{print $1}' | xargs -I{} docker inspect -f '{{.NetworkSettings.IPAddress }} {{ .Config.Hostname }}' {} > /etc/dnsmasq.hosts
[root@docker docker-hadoop]# cat /etc/dnsmasq.hosts 
172.17.0.29 master
172.17.0.28 slaver2
172.17.0.27 slaver1
[root@docker docker-hadoop]# service dnsmasq restart
[root@docker docker-hadoop]# ssh hadoop@master

[hadoop@master ~]$ ssh-copy-id master
[hadoop@master ~]$ ssh-copy-id localhost
[hadoop@master ~]$ ssh-copy-id slaver1
[hadoop@master ~]$ ssh-copy-id slaver2
[hadoop@master spark-1.1.0-bin-2.5.1]$ sbin/start-all.sh 
[hadoop@master spark-1.1.0-bin-2.5.1]$ /opt/jdk1.7.0_67/bin/jps  -m
266 Jps -m
132 Master --ip master --port 7077 --webui-port 8080

```

通过网页可以查看集群的状态：

![](http://file.bmob.cn/M00/1E/F8/wKhkA1RClV2AE0biAAEmpXJlzTc914.png)

运行任务连接到master：

```
[hadoop@master spark-1.1.0-bin-2.5.1]$ bin/spark-shell --master spark://master:7077
...
14/10/17 11:31:08 INFO BlockManagerMasterActor: Registering block manager slaver2:55473 with 265.4 MB RAM
14/10/17 11:31:09 INFO BlockManagerMasterActor: Registering block manager slaver1:33441 with 265.4 MB RAM

scala> 
```

![](http://file.bmob.cn/M00/1E/F9/wKhkA1RCmG-AO--XAAD84ATrCew955.png)

从上图可以看到，程序已经正确连接到spark集群，master为driver，任务节点为slaver1和slaver2。下面运行下程序，然后通过网页查看运行的状态。

```
scala> val textFile=sc.textFile("README.md")
scala> textFile.count()
scala> textFile.map(_.split(" ").size).reduce((a,b) => if(a>b) a else b)
```

![](http://file.bmob.cn/M00/1E/F9/wKhkA1RCmdmAB3M9AAFIzMb4yk0370.png)

系统安装好了，启动spark-standalone集群和hadoop-yarn一样。配置ssh、java，然后启动，配合网页8080/4040可以实时的了解任务的指标。

## yarn集群

如果你是按照前面的步骤来操作的，需要先把spark-standalone的集群停掉。端口8080和yarn web使用端口冲突，会导致yarn启动失败。

修改spark-env.sh，添加HADOOP_CONF_DIR参数。然后提交任务到yarn上执行就行了。

```
[hadoop@master spark-1.1.0-bin-2.5.1]$ cat conf/spark-env.sh
#!/usr/bin/env bash

JAVA_HOME=/opt/jdk1.7.0_67 

HADOOP_CONF_DIR=/opt/hadoop-2.5.1/etc/hadoop

[hadoop@master spark-1.1.0-bin-2.5.1]$ bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn-cluster lib/spark-examples-1.1.0-hadoop2.5.1.jar  10
```

![](http://file.bmob.cn/M00/1E/FD/wKhkA1RCszeAALCPAAK1Nzk6faQ330.png)

运行的结果输出在driver的slaver2节点，对应输出型来说不是很直观。spark-yarn提供了另一种方式，driver直接本地运行*yarn-client*。

```
[hadoop@master spark-1.1.0-bin-2.5.1]$ bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn-client lib/spark-examples-1.1.0-hadoop2.5.1.jar  10
...
14/10/17 13:31:02 INFO scheduler.TaskSetManager: Finished task 0.0 in stage 0.0 (TID 0) in 8248 ms on slaver1 (1/10)
14/10/17 13:31:02 INFO scheduler.TaskSetManager: Starting task 2.0 in stage 0.0 (TID 2, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:02 INFO scheduler.TaskSetManager: Finished task 1.0 in stage 0.0 (TID 1) in 231 ms on slaver1 (2/10)
14/10/17 13:31:02 INFO scheduler.TaskSetManager: Starting task 3.0 in stage 0.0 (TID 3, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:02 INFO scheduler.TaskSetManager: Finished task 2.0 in stage 0.0 (TID 2) in 158 ms on slaver1 (3/10)
14/10/17 13:31:02 INFO scheduler.TaskSetManager: Starting task 4.0 in stage 0.0 (TID 4, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 284 ms on slaver1 (4/10)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Starting task 5.0 in stage 0.0 (TID 5, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Finished task 4.0 in stage 0.0 (TID 4) in 175 ms on slaver1 (5/10)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Starting task 6.0 in stage 0.0 (TID 6, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Finished task 5.0 in stage 0.0 (TID 5) in 301 ms on slaver1 (6/10)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Starting task 7.0 in stage 0.0 (TID 7, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Finished task 6.0 in stage 0.0 (TID 6) in 175 ms on slaver1 (7/10)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Starting task 8.0 in stage 0.0 (TID 8, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Finished task 7.0 in stage 0.0 (TID 7) in 143 ms on slaver1 (8/10)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Finished task 8.0 in stage 0.0 (TID 8) in 164 ms on slaver1 (9/10)
14/10/17 13:31:03 INFO scheduler.TaskSetManager: Starting task 9.0 in stage 0.0 (TID 9, slaver1, PROCESS_LOCAL, 1228 bytes)
14/10/17 13:31:03 INFO cluster.YarnClientSchedulerBackend: Registered executor: Actor[akka.tcp://sparkExecutor@slaver2:51923/user/Executor#1132577949] with ID 1
14/10/17 13:31:04 INFO util.RackResolver: Resolved slaver2 to /default-rack
14/10/17 13:31:04 INFO scheduler.TaskSetManager: Finished task 9.0 in stage 0.0 (TID 9) in 397 ms on slaver1 (10/10)
14/10/17 13:31:04 INFO cluster.YarnClientClusterScheduler: Removed TaskSet 0.0, whose tasks have all completed, from pool 
14/10/17 13:31:04 INFO scheduler.DAGScheduler: Stage 0 (reduce at SparkPi.scala:35) finished in 26.084 s
14/10/17 13:31:04 INFO spark.SparkContext: Job finished: reduce at SparkPi.scala:35, took 28.31400558 s
Pi is roughly 3.140248
```

thrift连接yarn运行时时受容器内存最大值限制，需要修改yarn-site.xml。

```
cat yarn-site.xml 
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>32000</value>
</property>

<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>32768</value>
</property>

<property>
  <name>yarn.scheduler.minimum-allocation-mb</name>
  <value>2048</value>
</property>

<property>
  <name>yarn.scheduler.maximum-allocation-mb</name>
  <value>32768</value>
</property>

./sbin/start-thriftserver.sh --executor-memory 29g --master yarn-client
```

不能直接把executor的内存设置为最大值，否则会报错：

```
Exception in thread "main" java.lang.IllegalArgumentException: Required executor memory (30720+2150 MB) is above the max threshold (32768 MB) of this cluster!
```

## 总结

本文主要是搭建spark的环境搭建，本地运行、以及在docker中搭建spark集群、yarn集群三种方式。本地运行最简单方便，但是没有模拟到集群环境；spark提供了yarn框架上的实现，直接提交任务到yarn即可；spark集群相对比较简单和方便，接下来的远程调试主要通过spark伪分布式集群方式来进行。

## 参考

* [Building Spark with Maven](http://spark.apache.org/docs/latest/building-with-maven.html)
* [Quick Start](http://spark.apache.org/docs/latest/quick-start.html)
* [Spark Standalone Mode](http://spark.apache.org/docs/latest/spark-standalone.html)
* [Spark Configuration](http://spark.apache.org/docs/latest/configuration.html)
* [DNS](http://www.07net01.com/linux/zuixindnsmasqanzhuangbushuxiangjie_centos6__653221_1381214991.html)
* [spark上安装mysql与hive](http://blog.csdn.net/hwssg/article/details/38424529]

## 后记 Spark-1.3.0

### 编译1.3.0(cygwin)

```
export MAVEN_OPTS="-Xmx3g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
mvn package eclipse:eclipse -Phadoop-2.2 -Pyarn -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests

# mvn package eclipse:eclipse -Phadoop-2.2 -Pyarn -Phive -Phive-thriftserver -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests
# find . -name ".classpath" | xargs -I{} sed -i 's/ including="\*\*\/\*\.java"//' {}

dos2unix make-distribution.sh
./make-distribution.sh --mvn `which mvn` --tgz  --skip-java-test -Phadoop-2.2 -Pyarn -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests

# linux环境部署
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ find bin/* -perm /u+x | xargs -I{} sed -i 's/^M//g' {} 
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ find sbin/* -perm /u+x | xargs -I{} sed -i 's/^M//g' {} 

```

这个版本，windows-cygwin编译的shell文件也是**windows的换行符**！！需要注意下！

### spark-1.3.0运行spark-sql

```
$ export MAVEN_OPTS="-Xmx3g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
$ mvn package eclipse:eclipse -Phadoop-2.2 -Pyarn -Phive -Phive-thriftserver -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests

$ ./make-distribution.sh --mvn `which mvn` --tgz  --skip-java-test -Phadoop-2.2 -Pyarn -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests
```

1 连接到hive-engine

hive的`hive.execution.engine`的tez，添加tez的jar和hive-site到CLASSPATH。

包的导入以及配置：（如果使用meta-service的就不用这么麻烦）

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ vi conf/spark-env.sh 
...
JAVA_HOME=/home/eshore/jdk1.7.0_60

# log4j

__add_to_classpath() {

  root=$1

  if [ -d "$root" ] ; then
    for f in `ls $root/*.jar | grep -v -E '/hive.*.jar'`  ; do
      if [ -n "$SPARK_DIST_CLASSPATH" ] ; then
        export SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH:$f
      else
        export SPARK_DIST_CLASSPATH=$f
      fi
    done
  fi

}

__add_to_classpath "/home/eshore/tez-0.4.0-incubating"
__add_to_classpath "/home/eshore/tez-0.4.0-incubating/lib"
__add_to_classpath "/home/eshore/apache-hive-0.13.1/lib"

export HADOOP_CONF_DIR=/data/opt/ibm/biginsights/hadoop-2.2.0/etc/hadoop
export SPARK_CLASSPATH=/home/eshore/spark-1.3.0-bin-2.2.0/conf:$HADOOP_CONF_DIR

不能直接把hive的包全部加进去，hive-0.13.1a和hive-0.13.1的部分包不一致！！

	java.lang.NoSuchMethodException: org.apache.hadoop.hive.ql.exec.Utilities.deserializeObjectByKryo(com.esotericsoftware.kryo.Kryo, java.io.InputStream, java.lang.Class)

	private static java.lang.Object org.apache.hadoop.hive.ql.exec.Utilities.deserializeObjectByKryo(org.apache.hive.com.esotericsoftware.kryo.Kryo,java.io.InputStream,java.lang.Class)

&& 如果不依赖tez，可以直接把datanucleus的三个包拷贝到lib目录下。

[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ ll lib
total 262364
-rw-rw-r-- 1 hadoop hadoop    339666 Mar 25 19:35 datanucleus-api-jdo-3.2.6.jar
-rw-rw-r-- 1 hadoop hadoop   1890075 Mar 25 19:35 datanucleus-core-3.2.10.jar
-rw-rw-r-- 1 hadoop hadoop   1809447 Mar 25 19:35 datanucleus-rdbms-3.2.9.jar
-rwxr-xr-x 1 hadoop hadoop   4136686 Mar 31 13:05 spark-1.3.0-yarn-shuffle.jar
-rwxr-xr-x 1 hadoop hadoop 154198768 Mar 31 13:05 spark-assembly-1.3.0-hadoop2.2.0.jar
-rwxr-xr-x 1 hadoop hadoop 106275583 Mar 31 13:05 spark-examples-1.3.0-hadoop2.2.0.jar
	
[eshore@bigdatamgr1 conf]$ ll
...
lrwxrwxrwx 1 eshore biadmin   50 Mar 31 13:26 hive-site.xml -> /home/eshore/apache-hive-0.13.1/conf/hive-site.xml
-rw-r--r-- 1 eshore biadmin  632 Mar 31 15:12 log4j.properties
lrwxrwxrwx 1 eshore biadmin   44 Mar 31 10:20 slaves -> /data/opt/ibm/biginsights/hadoop-conf/slaves
-rwxr-xr-x 1 eshore biadmin 3380 Mar 31 16:17 spark-env.sh
lrwxrwxrwx 1 eshore biadmin   62 Mar 31 16:17 tez-site.xml -> /data/opt/ibm/biginsights/hadoop-2.2.0/etc/hadoop/tez-site.xml
```

也可以起hive-metaserver，然后spark通过连接meta即可：

```
# 起meta服务
nohup bin/hive --service metastore > metastore.log 2>&1 &

# hive客户端配置
vi hive-site.xml
<property>
  <name>hive.metastore.uris</name>
  <value>thrift://DataNode2:9083</value>
  <description>Thrift uri for the remote metastore. Used by metastore client to connect to remote metastore.</description>
</property>
```

2 运行：

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$  bin/spark-sql 2>sql.log
SET spark.sql.hive.version=0.13.1
spark-sql> show databases;
default
neva2dta
spark-sql> show tables;
pokes   false
t_neva2_dps_xdr false
t_neva2_ipdr_xdr        false
spark-sql> select count(*) from pokes;
500
spark-sql> 

[eshore@bigdatamgr1 conf]$ vi spark-env.sh 
#!/usr/bin/env bash

JAVA_HOME=/home/eshore/jdk1.7.0_60
SPARK_CLASSPATH='/home/eshore/apache-hive-0.13.1/lib/*:/home/eshore/tez-0.4.0-incubating/*:/home/eshore/tez-0.4.0-incubating/lib/*'

# 同步
[eshore@bigdatamgr1 ~]$ for h in `cat ~/spark-1.3.0-bin-2.2.0/conf/slaves` ; do rsync -vaz /data/opt/ibm/biginsights/hadoop-2.2.0 $h:/data/opt/ibm/biginsights/  ; done

```

运行hivesever服务

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ cat start_thrift.sh 
#!/bin/bash
# hive-classpath已经在spark-env.sh中添加

./sbin/start-thriftserver.sh --master spark://bigdatamgr1:7077 --executor-memory 16g
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ ./start_thrift.sh 

[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ bin/beeline -u jdbc:hive2://bigdatamgr1:10001 -n eshore -p '' 

```

上面这么写有个问题，尽管thrift启动正常，但是shell总是打印错误：

```
failed to launch org.apache.spark.sql.hive.thriftserver.HiveThriftServer2:
  ========================================
  
full log in /home/eshore/spark-1.3.0-bin-2.2.0/sbin/../logs/spark-eshore-org.apache.spark.sql.hive.thriftserver.HiveThriftServer2-1-bigdatamgr1.out
```

比较隐晦，问题在`sbin/spark-daemon.sh`，启动完后通过`if [[ ! $(ps -p "$newpid" -o args=) =~ $command ]]; then`（其中`=~`表示正则匹配，最终`spark-class.sh`调用java会由于加上classpath），而上面的classpath会很长，导致上面的匹配失败！！

```
[hadoop@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ vi bin/spark-class
...
  exec "$RUNNER" -cp "$CLASSPATH" $JAVA_OPTS "$@"
fi

# 匹配失败时的值
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ ps -p 1925344 -o args=
/home/eshore/jdk1.7.0_60/bin/java -cp :/home/eshore/spark-1.3.0-bin-2.2.0/sbin/../conf:/home/eshore/spark-1.3.0-bin-2.2.0/lib/spark-assembly-1.3.0-hadoop2.2.0.jar:/home/eshore/spark

```

#### 解决办法

先看实验：

```
[dpi@dacs tmp]$ java -cp ~/kettle/data-integration/lib/mysql-connector-java-5.1.31-bin.jar:. JDBCConnTest

[dpi@dacs tmp]$ echo $CLASSPATH
.
[dpi@dacs tmp]$ export CLASSPATH=~/kettle/data-integration/lib/mysql-connector-java-5.1.31-bin.jar
[dpi@dacs tmp]$ java JDBCConnTest
错误: 找不到或无法加载主类 JDBCConnTest
[dpi@dacs tmp]$ java -cp . JDBCConnTest
java.lang.ClassNotFoundException: com.mysql.jdbc.Driver

[dpi@dacs tmp]$ echo $CLASSPATH
/home/dpi/kettle/data-integration/lib/mysql-connector-java-5.1.31-bin.jar
[dpi@dacs tmp]$ export CLASSPATH=~/kettle/data-integration/lib/mysql-connector-java-5.1.31-bin.jar:.
[dpi@dacs tmp]$ java JDBCConnTest
```

设置cp后会覆盖CLASSPATH。所以问题的解决方法：直接把cp的路径删掉（不添加），前面已经export了classpath。java程序会去主动获取改环境变量。

```
  export CLASSPATH
  exec "$RUNNER" $JAVA_OPTS "$@"
``` 

效果如下：

```
++ ps -p 1932338 -o args=
+ [[ ! /home/eshore/jdk1.7.0_60/bin/java -XX:MaxPermSize=128m -Xms512m -Xmx512m org.apache.spark.deploy.SparkSubmit --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 --executor-memory 48g spark-internal =~ org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 ]]
```

* [=~的作用]<http://bbs.chinaunix.net/thread-1623121-1-1.html>
* <http://docs.oracle.com/javase/tutorial/essential/environment/paths.html>
* <https://docs.oracle.com/javase/8/docs/technotes/tools/windows/classpath.html>

### Spark-HA

仅需要配置，重启spark集群即可。

```
[eshore@bigdata8 spark-1.3.0-bin-2.2.0]$ cat conf/spark-env.sh
...
SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=bi-00-01.bi.domain.com:2181 -Dspark.deploy.zookeeper.dir=/spark"

[eshore@bigdatamgr1 conf]$ vi spark-defaults.conf 
spark.master                     spark://bigdatamgr1:7077,bigdata8:7077
...
```

各个master要单独的启动:

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ sbin/start-all.sh 
[eshore@bigdata8 spark-1.3.0-bin-2.2.0]$ sbin/start-master.sh 
```

通过查看<http://bigdata8:8080/>当前的状态为**STANDBY**。Workers列表为空。

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ sbin/stop-master.sh 
```

停了bigdatamgr1后，刷新`bigdata8:8080`页面等1分钟左右就变成ALIVE，然后其他所有的节点也连接到bigdata8了。

* <http://www.cnblogs.com/byrhuangqiang/p/3937654.html>
* <http://spark.apache.org/docs/latest/spark-standalone.html#high-availability>
