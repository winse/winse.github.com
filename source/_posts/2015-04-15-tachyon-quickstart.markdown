---
layout: post
title: "Tachyon入门指南"
date: 2015-04-15 22:56:09 +0800
comments: true
categories: [tachyon]
---

tachyon程序是在HDFS与程序之间缓冲，相当于CPU与磁盘设备之间内存的功能。tachyon提供了TachyonFS、TachyonFile等API使操作起来更像一个文件系统；同时实现了HDFS的FileSystem接口，方便原有程序的迁移，只要把url的模式（schema）hdfs改成tachyon。

tachyon和HDFS一样也是master-slaver（worker）结构：master保存元数据，worker节点使用内存盘缓冲数据。

## 部署集群

下载tachyon的编译文件后，按下面的步骤部署：

* 解压
* 修改conf/tachyon-env.sh（JAVA_HOME，TACHYON_UNDERFS_ADDRESS，TACHYON_MASTER_ADDRESS）
* 修改conf/worker
* 同步代码到workers子节点
* 格式化tachyon（建立master和worker所需的各种目录）
* 挂载内存盘
* 启动集群
* 通过19999端口访问

如果hadoop集群的版本不是最新的2.6.0，需要手工编译源码：

```
$ mvn clean package assembly:single -Dhadoop.version=2.2.0 -DskipTests -Dmaven.javadoc.skip=true
```

同步程序的脚本如下：

```
[eshore@bigdatamgr1 ~]$ for h in `cat slaves ` ; do  rsync -vaz tachyon-0.6.1 $h:~/ --exclude=logs --exclude=underfs --exclude=journal ; done
```

用tachyon用户格式化：

```
bin/tachyon format
```

使用root挂载内存盘：

```
bin/tachyon-mount.sh Mount workers
for h in `cat slaves ` ; do  ssh $h "chmod 777 /mnt/ramdisk; chmod 777 /mnt/tachyon_default_home"  ; done
```

确认下worker节点是否有underfs/tmp/tachyon/data，如果没有手动创建下。

```
[eshore@bigdatamgr1 ~]$ for h in `cat slaves ` ; do ssh $h mkdir -p ~/tachyon-0.6.1/underfs/tmp/tachyon/data ; done
```

启动集群：

```
[eshore@bigdatamgr1 tachyon-0.6.1]$ bin/tachyon-start.sh all NoMount
```

上传文件到tachyon：（注意，这里是在worker节点！）

```
[eshore@bigdata1 tachyon-0.6.1]$ bin/tachyon tfs copyFromLocal README.md /
Copied README.md to /
```

## 集成到Spark

注意，这里是在worker节点，使用local本地集群的方式（spark集群资源全部被spark-sql占用了，导致提交的任务分配不到资源！）。

```
[eshore@bigdata1 spark-1.3.0-bin-2.2.0]$ export SPARK_CLASSPATH=/home/eshore/tachyon-0.6.1/core/target/tachyon-0.6.1-jar-with-dependencies.jar 
[eshore@bigdata1 spark-1.3.0-bin-2.2.0]$ bin/spark-shell --master local[1] -Dspark.ui.port=4041
scala> val s = sc.textFile("tachyon://bigdatamgr1:19998/README.md")
s: org.apache.spark.rdd.RDD[String] = tachyon://bigdatamgr1:19998/README.md MapPartitionsRDD[1] at textFile at <console>:21

scala> s.count()
15/04/03 11:13:09 WARN : tachyon.home is not set. Using /mnt/tachyon_default_home as the default value.
res0: Long = 45

scala> val wordCounts = s.flatMap(_.split(" ")).map((_,1)).reduceByKey(_+_)
wordCounts: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[4] at reduceByKey at <console>:23

scala> wordCounts.saveAsTextFile("tachyon://bigdatamgr1:19998/wordcount-README")

[eshore@bigdatamgr1 tachyon-0.6.1]$ bin/tachyon tfs ls /wordcount-README/
1407.00 B 04-03-2015 11:16:05:483  In Memory      /wordcount-README/part-00000
0.00 B    04-03-2015 11:16:05:787  In Memory      /wordcount-README/_SUCCESS
```

为啥要在worker节点运行呢？不能在master节点运行？运行肯定是可以的：

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ export SPARK_CLASSPATH=/home/eshore/tachyon-0.6.1/core/target/tachyon-0.6.1-jar-with-dependencies.jar
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ bin/spark-shell --master local[1] --jars /home/eshore/tachyon-0.6.1/core/target/tachyon-0.6.1-jar-with-dependencies.jar

scala> val s = sc.textFile("tachyon://bigdatamgr1:19998/NOTICE")
s: org.apache.spark.rdd.RDD[String] = tachyon://bigdatamgr1:19998/NOTICE MapPartitionsRDD[1] at textFile at <console>:15

scala> s.count()
15/04/13 16:05:45 WARN BlockReaderLocal: The short-circuit local reads feature cannot be used because libhadoop cannot be loaded.
15/04/13 16:05:45 WARN : tachyon.home is not set. Using /mnt/tachyon_default_home as the default value.
java.io.IOException: The machine does not have any local worker.
        at tachyon.client.BlockOutStream.<init>(BlockOutStream.java:94)
        at tachyon.client.BlockOutStream.<init>(BlockOutStream.java:65)
        at tachyon.client.RemoteBlockInStream.read(RemoteBlockInStream.java:204)
        at tachyon.hadoop.HdfsFileInputStream.read(HdfsFileInputStream.java:142)
        at java.io.DataInputStream.read(DataInputStream.java:100)
        at org.apache.hadoop.util.LineReader.readDefaultLine(LineReader.java:211)
        at org.apache.hadoop.util.LineReader.readLine(LineReader.java:174)
        at org.apache.hadoop.mapred.LineRecordReader.next(LineRecordReader.java:206)
        at org.apache.hadoop.mapred.LineRecordReader.next(LineRecordReader.java:45)
        at org.apache.spark.rdd.HadoopRDD$$anon$1.getNext(HadoopRDD.scala:245)
        at org.apache.spark.rdd.HadoopRDD$$anon$1.getNext(HadoopRDD.scala:212)
        at org.apache.spark.util.NextIterator.hasNext(NextIterator.scala:71)
        at org.apache.spark.InterruptibleIterator.hasNext(InterruptibleIterator.scala:39)
        at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
        at org.apache.spark.util.Utils$.getIteratorSize(Utils.scala:1466)
        at org.apache.spark.rdd.RDD$$anonfun$count$1.apply(RDD.scala:1006)
        at org.apache.spark.rdd.RDD$$anonfun$count$1.apply(RDD.scala:1006)
        at org.apache.spark.SparkContext$$anonfun$runJob$5.apply(SparkContext.scala:1497)
        at org.apache.spark.SparkContext$$anonfun$runJob$5.apply(SparkContext.scala:1497)
        at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:61)
        at org.apache.spark.scheduler.Task.run(Task.scala:64)
        at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:203)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:745)
res0: Long = 2
```

两个点：

* 这里是运行的spark local集群；
* 运行当然没有问题，但是会打印不和谐的**The machine does not have any local worker**警告日志。这与FileSystem的获取输入流`ReadType.CACHE`实现有关（见源码HdfsFileInputStream）。

```
mTachyonFileInputStream = mTachyonFile.getInStream(ReadType.CACHE);
```

如果master为spark集群，spark-driver不管运行在哪台集群都没有问题。因为，此时运行任务的spark-worker就是tachyon-worker节点啊，当然就有local worker了。

为了更深入的了解，还可以试验一下`ReadType.CACHE`的作用：原本不在内存的数据，计算后就会被载入到缓冲（内存）！！

可以再试一次，先从内存中删掉（此处underfs配置存储在HDFS）

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ ~/tachyon-0.6.1/bin/tachyon tfs free /NOTICE
/NOTICE was successfully freed from memory.

[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ ~/tachyon-0.6.1/bin/tachyon tfs fileinfo /NOTICE
/NOTICE with file id 2 has the following blocks: 
ClientBlockInfo(blockId:2147483648, offset:0, length:62, locations:[NetAddress(mHost:bigdata8, mPort:-1, mSecondaryPort:-1), NetAddress(bigdata6, mPort:-1, mSecondaryPort:-1), NetAddress(mHost:bigdata5, mPort:-1, mSecondaryPort:-1)])
```

再次运行count：

```
scala> s.count()
res1: Long = 2
```

再次查看文件状态：

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ ~/tachyon-0.6.1/bin/tachyon tfs fileinfo /NOTICE
/NOTICE with file id 2 has the following blocks: 
ClientBlockInfo(blockId:2147483648, offset:0, length:62, locations:[NetAddress(mHost:bigdata1, mPort:29998, mSecondaryPort:29999)])
```

此时文件对应的block所在机器变成了bigdata1，也就是spark-worker运行的节点（这里用local，worker和driver都在bigdata1上）。

参考

* <http://tachyon-project.org/Running-Tachyon-on-a-Cluster.html>
* <http://spark.apache.org/docs/latest/configuration.html>
* <http://tachyon-project.org/Running-Spark-on-Tachyon.html>

## 集成到Hadoop集群

```
[eshore@bigdatamgr1 ~]$ export HADOOP_CLASSPATH=/home/eshore/tachyon-0.6.1/core/target/tachyon-0.6.1-jar-with-dependencies.jar

[eshore@bigdatamgr1 hadoop-2.2.0]$ bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.2.0.jar wordcount -libjars /home/eshore/tachyon-0.6.1/core/target/tachyon-0.6.1-jar-with-dependencies.jar tachyon://bigdatamgr1:19998/NOTICE tachyon://bigdatamgr1:19998/NOTICE-wordcount

[eshore@bigdatamgr1 hadoop-2.2.0]$ ~/tachyon-0.6.1/bin/tachyon tfs cat /NOTICE-wordcount/part-r-00000
2012-2014       1
Berkeley        1
California,     1
Copyright       1
Tachyon 1
University      1
of      1
```

## 后记

当前apache开源大部分集群的部署都是同一种模式，源码也基本都是用maven来进行构建。部署其实没有什么难度，如果是应用到spark、hadoop这样的平台，其实只要部署，然后用FileSystem的接口就一切ok了。但是要了解其原理，官网的文档也不是很全，那得需要深入源码。

入门写到这里，差不多了，下一篇从TachyonFS角度解析tachyon。

## 附录

* spark-env.sh

```
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
export SPARK_CLASSPATH=$SPARK_CLASSPATH:/home/eshore/spark-1.3.0-bin-2.2.0/conf:$HADOOP_CONF_DIR

# HA
SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=bi-00-01.bi.domain.com:2181 -Dspark.deploy.zookeeper.dir=/spark"

[eshore@bigdatamgr1 ~]$ for h in `cat slaves ` ; do rsync -vaz spark-1.3.0-bin-2.2.0 $h:~/ --exclude=logs --exclude=metastore_db --exclude=work --delete ; done
```



