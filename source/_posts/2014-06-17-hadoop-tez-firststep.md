---
layout: post
title: tez编译及使用
date: 2014-6-17 20:22:58
categories: [hadoop, tez]
---

## 初步了解

hadoop2自带的mapreduce任务中间只能传递一次，也即一个任务只能聚合一次。而tez项目是对原有yarn架构的一个拓展，使用DAG（无环有向图）实现MRR的任务框架。

![](http://farm6.staticflickr.com/5571/14256993179_4990fc86d5_o.png)

上图中，左边的MR任务完成一个步骤后，需要进行**数据存储**后再执行另一个任务来进行第二个“reduce”； 而tez则可以在reduce后继续执行reduce，减少了中间过程的IO以及mapreduce的启动时间。

## 环境整合

* [Install/Deploy](http://tez.incubator.apache.org/install.html)
* hadoop-2.2.0（umcc97-44：hdfs， umcc97-79：yarn）
* windows下使用Cygwin编译

### 下载编译tez

首先下载[tez-0.4.0-incubating.tar.gz](http://apache.fayea.com/apache-mirror/incubator/tez/tez-0.4.0-incubating/)，同时还需要[protoc](http://code.google.com/p/protobuf)的程序支持（编译[hadoop源码](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html)也需要这个的）。
解压后，使用mvn编译。

```
Administrator@winseliu /cygdrive/e/local/libs/big
$ tar zxvf tez-0.4.0-incubating.tar.gz

Administrator@winseliu /cygdrive/e/local/libs/big
$ cd tez-0.4.0-incubating/

Administrator@winseliu /cygdrive/e/local/libs/big/tez-0.4.0-incubating
$ mvn install -DskipTests -Dmaven.javadoc.skip
...
[INFO] Reactor Summary:
[INFO]
[INFO] tez ............................................... SUCCESS [1.518s]
[INFO] tez-api ........................................... SUCCESS [8.890s]
[INFO] tez-common ........................................ SUCCESS [0.725s]
[INFO] tez-runtime-internals ............................. SUCCESS [2.529s]
[INFO] tez-runtime-library ............................... SUCCESS [5.100s]
[INFO] tez-mapreduce ..................................... SUCCESS [3.666s]
[INFO] tez-mapreduce-examples ............................ SUCCESS [2.692s]
[INFO] tez-dag ........................................... SUCCESS [13.943s]
[INFO] tez-tests ......................................... SUCCESS [1.691s]
[INFO] tez-dist .......................................... SUCCESS [14.370s]
[INFO] Tez ............................................... SUCCESS [0.245s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 55.791s
[INFO] Finished at: Tue Jun 17 17:33:45 CST 2014
[INFO] Final Memory: 35M/151M
[INFO] ------------------------------------------------------------------------

```

### 上传tez程序的jars到HDFS

为了简单我直接把tez放到开发环境的集群上面去测试了。放到本地环境应该也类似。

```
Administrator@winseliu /cygdrive/e/local/libs/big/tez-0.4.0-incubating
$ cd tez-dist/

Administrator@winseliu /cygdrive/e/local/libs/big/tez-0.4.0-incubating/tez-dist
$ cd target/

Administrator@winseliu /cygdrive/e/local/libs/big/tez-0.4.0-incubating/tez-dist/target
$ export HADOOP_USER_NAME=hadoop

Administrator@winseliu /cygdrive/e/local/libs/big/tez-0.4.0-incubating/tez-dist/target
$  hadoop dfs -put tez-0.4.0-incubating/tez-0.4.0-incubating/ hdfs://umcc97-44:9000/apps/
DEPRECATED: Use of this script to execute hdfs command is deprecated.
Instead use the hdfs command for it.

```

### 配置集群环境

首先看下原来集群的classpath路径，由于已经包括了etc/hadoop目录，所以这里我直接把`tez-site.xml`放到该目录下。把所有的tez-lib上传到share目录下，并添加到HADOOP_CLASSPATH。

```
  [hadoop@umcc97-79 hadoop]$ hadoop classpath
  /home/hadoop/hadoop-2.2.0/etc/hadoop:/home/hadoop/hadoop-2.2.0/share/hadoop/common/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/common/*:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/*:/home/hadoop/hadoop-2.2.0/share/hadoop/mapreduce/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/mapreduce/*:/home/hadoop/hadoop-2.2.0/contrib/capacity-scheduler/*.jar
  
  # 用于map/reduce
  [hadoop@umcc97-79 hadoop]$ cat tez-site.xml 
  <?xml version="1.0"?>
  <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
  
  <!-- Put site-specific property overrides in this file. -->
  
  <configuration>
    <property>
      <name>tez.lib.uris</name>
      <value>${fs.default.name}/apps/tez-0.4.0-incubating,${fs.default.name}/apps/tez-0.4.0-incubating/lib/</value>
    </property>
  </configuration>
  [hadoop@umcc97-79 hadoop]$ 
  
  [hadoop@umcc97-79 hadoop]$ cd ~/hadoop-2.2.0/share/hadoop/tez/
  [hadoop@umcc97-79 tez]$ ll
  total 9616
  -rw-r--r-- 1 hadoop hadoop  303139 Jun 17 17:33 avro-1.7.4.jar
  -rw-r--r-- 1 hadoop hadoop   41123 Jun 17 17:33 commons-cli-1.2.jar
  -rw-r--r-- 1 hadoop hadoop  610259 Jun 17 17:33 commons-collections4-4.0.jar
  -rw-r--r-- 1 hadoop hadoop 1648200 Jun 17 17:33 guava-11.0.2.jar
  -rw-r--r-- 1 hadoop hadoop  710492 Jun 17 17:33 guice-3.0.jar
  -rw-r--r-- 1 hadoop hadoop  656365 Jun 17 17:33 hadoop-mapreduce-client-common-2.2.0.jar
  -rw-r--r-- 1 hadoop hadoop 1455001 Jun 17 17:33 hadoop-mapreduce-client-core-2.2.0.jar
  -rw-r--r-- 1 hadoop hadoop   21537 Jun 17 17:33 hadoop-mapreduce-client-shuffle-2.2.0.jar
  -rw-r--r-- 1 hadoop hadoop   81743 Jun 17 17:33 jettison-1.3.4.jar
  -rw-r--r-- 1 hadoop hadoop  533455 Jun 17 17:33 protobuf-java-2.5.0.jar
  -rw-r--r-- 1 hadoop hadoop  995968 Jun 17 17:33 snappy-java-1.0.4.1.jar
  -rw-r--r-- 1 hadoop hadoop  749917 Jun 17 17:33 tez-api-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop   34049 Jun 17 17:33 tez-common-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop  970987 Jun 17 17:33 tez-dag-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop  246409 Jun 17 17:33 tez-mapreduce-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop  199934 Jun 17 17:33 tez-mapreduce-examples-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop  114692 Jun 17 17:33 tez-runtime-internals-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop  352177 Jun 17 17:33 tez-runtime-library-0.4.0-incubating.jar
  -rw-r--r-- 1 hadoop hadoop    6845 Jun 17 17:33 tez-tests-0.4.0-incubating.jar
  [hadoop@umcc97-79 tez]$ 
  
  # 用于client任务提交
  [hadoop@umcc97-79 hadoop]$ grep HADOOP_CLASSPATH hadoop-env.sh
  export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tez/*:${HADOOP_HOME}/share/hadoop/tez/lib/*:$HADOOP_CLASSPATH
  
  [hadoop@umcc97-79 hadoop]$ sed -n 19,23p mapred-site.xml
  <configuration>
    <property>
      <name>mapreduce.framework.name</name>
      <value>yarn-tez</value>
    </property>

```

### 同步，重启yarn

```
for h in `cat hadoop-2.2.0/etc/hadoop/slaves ` ; do rsync -vaz --exclude=logs --exclude=pid --exclude=tmp  hadoop-2.2.0 $h:~/ ; done

rsync -vaz --exclude=logs --exclude=pid --exclude=tmp  hadoop-2.2.0 umcc97-44:~/
```

### 测试效果

```
  [hadoop@umcc97-79 ~]$ hadoop classpath
  /home/hadoop/hadoop-2.2.0/etc/hadoop:/home/hadoop/hadoop-2.2.0/share/hadoop/common/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/common/*:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/*:/home/hadoop/hadoop-2.2.0/share/hadoop/mapreduce/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/mapreduce/*:/home/hadoop/hadoop-2.2.0/share/hadoop/tez/*:/home/hadoop/hadoop-2.2.0/share/hadoop/tez/lib/*:/home/hadoop/hadoop-2.2.0/contrib/capacity-scheduler/*.jar
  [hadoop@umcc97-79 ~]$ cd hadoop-2.2.0/share/hadoop/mapreduce/
  [hadoop@umcc97-79 mapreduce]$ hadoop jar hadoop-mapreduce-client-jobclient-2.2.0-tests.jar sleep -mt 1 -rt 1 -m 1 -r 1
  
    hadoop jar hadoop-2.2.0/share/hadoop/tez/tez-mapreduce-examples-0.4.0-incubating.jar orderedwordcount  /hello/in /hello/out
    hadoop fs -put hadoop-2.2.0/logs/yarn-hadoop-resourcemanager-umcc97-79.* /hello/in
    hadoop fs -rmr /hello/out
    hadoop jar hadoop-2.2.0/share/hadoop/tez/tez-mapreduce-examples-0.4.0-incubating.jar orderedwordcount  /hello/in /hello/out

```

### 回滚，使用时临时修改环境变量即可

使用了tez后，使用hive-0.12.0不能运行了。由于其他同事需要用hive，得把配置全部修改回去【[hive-0.13中使用tez]({{ BASE_PATH }}/blog/2014/06/21/upgrade-hive/)】。

其实在**提交任务**时指定配置参数即可。

```
[hadoop@umcc97-79 ~]$ export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tez/*:${HADOOP_HOME}/share/hadoop/tez/lib/*:$HADOOP_CLASSPATH
[hadoop@umcc97-79 ~]$ hadoop jar hadoop-2.2.0/share/hadoop/tez/tez-mapreduce-examples-0.4.0-incubating.jar orderedwordcount -Dmapreduce.framework.name=yarn-tez  /hello/in /hello/out
```

org.apache.tez.mapreduce.examples.OrderedWordCount不仅计算出了结果，同时按个数大小进行了排序。

问题： tez的任务的history还不知道怎么弄的，启动historyserver没作用。

