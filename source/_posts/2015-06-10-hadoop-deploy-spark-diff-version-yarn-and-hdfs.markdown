---
layout: post
title: "hadoop不同版本yarn和hdfs混搭，spark-yarn环境配置"
date: 2015-06-10 18:48:19 +0800
comments: true
categories: [hadoop, spark]
---

hadoop分为存储和计算两个主要的功能，hdfs步入hadoop2后不论稳定性还是HA等等功能都比hadoop1要更吸引人。hadoop-2.2.0的hdfs已经比较稳定，但是yarn高版本有更加丰富的功能。本文主要关注spark-yarn下日志的查看，以及spark-yarn-dynamic的配置。

hadoop-2.2.0的hdfs原本已经在使用的环境，在这基础上搭建运行yarn-2.6.0，以及spark-1.3.0-bin-2.2.0。

* 编译

我是在虚拟机里面编译，共享了host主机的maven库。参考【VMware共享目录】，【VMware-Centos6 Build hadoop-2.6】注意**cmake_symlink_library的异常，由于共享的windows目录下不能创建linux的软链接**

```
tar zxvf ~/hadoop-2.6.0-src.tar.gz 
cd hadoop-2.6.0-src/
mvn package -Pdist,native -DskipTests -Dtar -Dmaven.javadoc.skip=true

# 由于hadoop-hdfs还是2.2的，这里编译spark需要用2.2版本！
# 如果用2.6会遇到[UnsatisfiedLinkError:org.apache.hadoop.util.NativeCrc32.nativeComputeChunkedSumsByteArray ](http://blog.csdn.net/zeng_84_long/article/details/44340441)
cd spark-1.3.0
export MAVEN_OPTS="-Xmx3g -XX:MaxPermSize=1g -XX:ReservedCodeCacheSize=512m"
mvn clean package -Phadoop-2.2 -Pyarn -Phive -Phive-thriftserver -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests

vi make-distribution.sh #注释掉BUILD_COMMAND那一行，不重复执行package！
./make-distribution.sh  --mvn `which mvn` --tgz  --skip-java-test -Phadoop-2.6 -Pyarn -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -DskipTests
```

* 配置注意点

1. core-site不要全部拷贝原来的，只要一些主要的配置即可。
2. yarn-site的`yarn.resourcemanager.webapp.address`需要填写具体的地址，不能写`0.0.0.0`。
3. yarn-site的`yarn.nodemanager.aux-services`添加spark_shuffle服务。<https://spark.apache.org/docs/latest/job-scheduling.html#dynamic-resource-allocation> 
4. 把hive-site的文件拷贝/链接到spark的conf目录下。
5. spark-yarn-dynamic配置: <https://spark.apache.org/docs/latest/configuration.html#dynamic-allocation>

```
[eshore@bigdatamgr1 spark-1.3.0-bin-2.2.0]$ cat conf/spark-defaults.conf 
# spark.master                     spark://bigdatamgr1:7077,bigdata8:7077
# spark.eventLog.enabled           true
# spark.eventLog.dir               hdfs://namenode:8021/directory
# spark.executor.extraJavaOptions  -XX:+PrintGCDetails -Dkey=value -Dnumbers="one two three"
# spark.executor.extraJavaOptions       -Xmx16g -Xms16g -Xmn256m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:ParallelGCThreads=10
spark.driver.memory              48g
spark.executor.memory            48g
spark.sql.shuffle.partitions     200

#spark.scheduler.mode FAIR
spark.serializer  org.apache.spark.serializer.KryoSerializer
spark.driver.maxResultSize 8g
#spark.kryoserializer.buffer.max.mb 2048

spark.dynamicAllocation.enabled true
spark.dynamicAllocation.minExecutors 4
spark.shuffle.service.enabled true

[eshore@bigdatamgr1 conf]$ cat spark-env.sh 
#!/usr/bin/env bash

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
# this add tail of SPARK_CLASSPATH
__add_to_classpath "/home/eshore/apache-hive-0.13.1/lib"

#export HADOOP_CONF_DIR=/data/opt/ibm/biginsights/hadoop-2.2.0/etc/hadoop
export HADOOP_CONF_DIR=/home/eshore/hadoop-2.6.0/etc/hadoop
export SPARK_CLASSPATH=$SPARK_CLASSPATH:/home/eshore/spark-1.3.0-bin-2.2.0/conf:$HADOOP_CONF_DIR

# HA
SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=bi-00-01.bi.domain.com:2181 -Dspark.deploy.zookeeper.dir=/spark" 

SPARK_PID_DIR=${SPARK_HOME}/pids

```

* 同步

```
for h in `cat slaves ` ; do rsync -vaz hadoop-2.6.0 $h:~/ --delete --exclude=work --exclude=logs --exclude=metastore_db --exclude=data --exclude=pids ; done
```

* 启动spark-hive-thrift

./sbin/start-thriftserver.sh --executor-memory 29g --master yarn-client

对于多任务的集群来说，配置自动动态分配（类似资源池）更有利于资源的使用。可以通过【All Applications】-【ApplicationMaster】-【Executors】来观察执行进程的变化。

{% comment %} 
## 【ibm的hdfs2+jobtracker1配置】

```
[eshore@bigdatamgr1 ~]$ xsltproc format.xslt /data/opt/ibm/biginsights/hadoop-conf/core-site.xml 
fs.defaultFS=hdfs://bi-00-01.bi.domain.com:9000
fs.hdfs.impl=org.apache.hadoop.hdfs.DistributedFileSystem
io.file.buffer.size=65536
fs.checkpoint.dir=/data/hadoop/hdfs/namesecondary
hadoop.http.staticuser.user=biadmin
hadoop.proxyuser.eshore.groups=*
hadoop.proxyuser.eshore.hosts=*
hadoop.proxyuser.biadmin.groups=*
hadoop.proxyuser.biadmin.hosts=*
hadoop.proxyuser.bigsql.groups=*
hadoop.proxyuser.bigsql.hosts=*
hadoop.proxyuser.console.groups=*
hadoop.proxyuser.console.hosts=*
hadoop.proxyuser.hbase.groups=*
hadoop.proxyuser.hbase.hosts=*
hadoop.proxyuser.hdfs.groups=*
hadoop.proxyuser.hdfs.hosts=*
hadoop.proxyuser.hive.groups=*
hadoop.proxyuser.hive.hosts=*
hadoop.proxyuser.httpfs.groups=*
hadoop.proxyuser.httpfs.hosts=*
hadoop.proxyuser.mapred.groups=*
hadoop.proxyuser.mapred.hosts=*
hadoop.proxyuser.oozie.groups=*
hadoop.proxyuser.oozie.hosts=*
hadoop.tmp.dir=/data/var/ibm/biginsights/hadoop/tmp/${user.name}
io.compression.codecs=com.ibm.biginsights.compress.CmxCodec
fs.sftp.impl=com.ibm.biginsights.hadoop.fs.sftp.SFTPFileSystem

[eshore@bigdatamgr1 ~]$ xsltproc format.xslt /data/opt/ibm/biginsights/hadoop-conf/hdfs-site.xml 
dfs.blocksize=134217728
dfs.namenode.handler.count=64
dfs.datanode.handler.count=10
dfs.datanode.max.transfer.threads=8192
dfs.support.append=true
dfs.replication=3
dfs.webhdfs.enabled=true
dfs.client.read.shortcircuit=true
dfs.domain.socket.path=/var/run/hadoop/dn._PORT
dfs.client.file-block-storage-locations.timeout=3000
dfs.datanode.hdfs-blocks-metadata.enabled=true
dfs.cluster.administrators=biadmin,console,hdfs
dfs.datanode.address=0.0.0.0:50010
dfs.datanode.data.dir=/data/hadoop/hdfs/data
dfs.datanode.http.address=0.0.0.0:50075
dfs.datanode.ipc.address=0.0.0.0:50020
dfs.name.dir=/data/hadoop/hdfs/name
dfs.namenode.http-address=bi-00-01.bi.domain.com:50070
dfs.namenode.secondary.http-address=bi-01-02.bi.domain.com:50090
dfs.permissions.superusergroup=biadmin
dfs.support.broken.append=true
dfs.web.ugi=biadmin,biadmin
dfs.datanode.du.reserved=1156319728544
dfs.hosts=/data/opt/ibm/biginsights/hadoop-conf/includes

[eshore@bigdatamgr1 ~]$ xsltproc format.xslt /data/opt/ibm/biginsights/hadoop-conf/mapred-site.xml 
mapreduce.jobtracker.address=bi-00-01.bi.domain.com:9001
mapred.task.tracker.report.address=127.0.0.1:50039=fix port for tasktracker IPC server
mapred.job.tracker.handler.count=64
mapred.jobtracker.taskScheduler=com.ibm.biginsights.scheduler.WorkflowScheduler
mapred.tasktracker.map.tasks.maximum=2
mapred.tasktracker.reduce.tasks.maximum=2
mapreduce.map.java.opts=-Xmx1000m -Xms1000m -Xmn100m -Xtune:virtualized -Xshareclasses:name=mrscc_%g,groupAccess,cacheDir=/data/var/ibm/biginsights/hadoop/tmp,nonFatal -Xscmx20m
mapreduce.reduce.java.opts=-Xmx1000m -Xms1000m -Xmn100m -Xtune:virtualized -Xshareclasses:name=mrscc_%g,groupAccess,cacheDir=/data/var/ibm/biginsights/hadoop/tmp,nonFatal -Xscmx20m
io.sort.mb=256
io.sort.factor=10
mapred.reduce.slowstart.completed.maps=0.5
mapred.map.tasks.speculative.execution=false
mapred.reduce.tasks.speculative.execution=false
mapreduce.tasktracker.outofband.heartbeat=true
mapred.heartbeats.in.second=200
mapred.output.compression.type=BLOCK
mapred.jobinit.threads=4
mapreduce.jobtracker.staging.root.dir=/user
mapred.jobtracker.instrumentation=org.apache.hadoop.mapred.JobTrackerConfLogStreaming
mapred.acls.enabled=true
mapreduce.framework.name=classic
mapred.job.tracker.http.address=0.0.0.0:50030
mapred.local.dir=/data/hadoop/mapred/local
mapred.system.dir=/hadoop/mapred/system
mapred.task.tracker.http.address=0.0.0.0:50060
mapreduce.cluster.acls.enabled=true
mapreduce.cluster.administrators=biadmin,console,mapred
mapred.fairscheduler.allocation.file=/data/opt/ibm/biginsights/hadoop-conf/fair-scheduler.xml
mapreduce.jobtracker.hosts.filename=/data/opt/ibm/biginsights/hadoop-conf/includes
mapred.workflowscheduler.algorithm=AVERAGE_RESPONSE_TIME
mapred.workflowscheduler.config.file=/data/opt/ibm/biginsights/hadoop-conf/flex-scheduler.xml
adaptivemr.map.enable=false
adaptivemr.zookeeper.hosts=bi-00-01.bi.domain.com:2181
mapred.submit.replication=3
mapreduce.tasktracker.group=biadmin
mapreduce.tasktracker.taskcontroller=org.apache.hadoop.mapred.LinuxTaskController
```

## 【hadoop-2.2.0 hdfs带有HA的配置】

```
[hadoop@hadoop-master1 ~]$ xsltproc format.xslt hadoop-2.2.0/etc/hadoop/core-site.xml 
fs.defaultFS=hdfs://zfcluster
io.file.buffer.size=65536
hadoop.tmp.dir=/home/hadoop/hadoop-2.2.0/tmp
hadoop.proxyuser.hduser.hosts=*
hadoop.proxyuser.hduser.groups=*
ha.zookeeper.quorum=hadoop-master1:2181,hadoop-master2:2181,hadoop-slaver1:2181,hadoop-slaver2:2181,hadoop-slaver3:2181
fs.trash.interval=7200
hadoop.logfile.size=1000000000
hadoop.logfile.count=50
hadoop.native.lib=true
io.compression.codecs=org.apache.hadoop.io.compress.GzipCodec, org.apache.hadoop.io.compress.DefaultCodec, org.apache.hadoop.io.compress.BZip2Codec, org.apache.hadoop.io.compress.SnappyCodec

[hadoop@hadoop-master1 ~]$ xsltproc format.xslt hadoop-2.2.0/etc/hadoop/hdfs-site.xml 
dfs.namenode.name.dir=/home/hadoop/dfs/name
dfs.datanode.data.dir=/data1/hadoop/data,/data2/hadoop/data,/data3/hadoop/data,/data4/hadoop/data,/data5/hadoop/data,/data6/hadoop/data,/data7/hadoop/data,/data8/hadoop/data,/data9/hadoop/data,/data10/hadoop/data,/data11/hadoop/data,/data12/hadoop/data,/data13/hadoop/data,/data14/hadoop/data,/data15/hadoop/data
dfs.datanode.failed.volumes.tolerated=6
dfs.replication=3
dfs.webhdfs.enabled=true
dfs.nameservices=zfcluster
dfs.ha.namenodes.zfcluster=nn1,nn2
dfs.namenode.rpc-address.zfcluster.nn1=hadoop-master1:8020
dfs.namenode.rpc-address.zfcluster.nn2=hadoop-master2:8020
dfs.namenode.http-address.zfcluster.nn1=hadoop-master1:50070
dfs.namenode.http-address.zfcluster.nn2=hadoop-master2:50070
dfs.namenode.shared.edits.dir=qjournal://hadoop-master1:8485;hadoop-master2:8485;hadoop-slaver1:8485;hadoop-slaver2:8485;hadoop-slaver3:8485/zfcluster
dfs.client.failover.proxy.provider.zfcluster=org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider
dfs.ha.fencing.methods=sshfence
dfs.ha.fencing.ssh.private-key-files=/home/hadoop/.ssh/id_rsa
dfs.journalnode.edits.dir=/home/hadoop/journal
dfs.ha.automatic-failover.enabled=true

[hadoop@hadoop-master1 ~]$ xsltproc format.xslt hadoop-2.2.0/etc/hadoop/mapred-site.xml
mapreduce.framework.name=yarn
mapreduce.jobhistory.address=hadoop-master1:10020
mapreduce.jobhistory.webapp.address=hadoop-master1:19888
mapred.child.java.opts=-Xmx2000m
mapreduce.map.memory.mb=3072
mapreduce.reduce.memory.mb=3072
mapreduce.map.java.opts=-Xmx3072m
mapreduce.reduce.java.opts=-Xmx3072m
mapreduce.map.output.compress=true
mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.SnappyCodec
mapreduce.output.fileoutputformat.compress=true
mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.SnappyCodec
mapred.output.compression.codec=org.apache.hadoop.io.compress.SnappyCodec
mapred.output.compression.type=BLOCK

[hadoop@hadoop-master1 ~]$ xsltproc format.xslt hadoop-2.2.0/etc/hadoop/yarn-site.xml 
yarn.nodemanager.aux-services=mapreduce_shuffle
yarn.nodemanager.aux-services.mapreduce.shuffle.class=org.apache.hadoop.mapred.ShuffleHandler
yarn.resourcemanager.address=hadoop-master1:8032
yarn.resourcemanager.scheduler.address=hadoop-master1:8030
yarn.resourcemanager.resource-tracker.address=hadoop-master1:8031
yarn.resourcemanager.admin.address=hadoop-master1:8033
yarn.resourcemanager.webapp.address=hadoop-master1:8088
yarn.nodemanager.resource.memory-mb=51200
yarn.scheduler.minimum-allocation-mb=1024
yarn.nodemanager.pmem-check-enabled=false
yarn.nodemanager.vmem-check-enabled=false
```

## 【hadoop-yarn-2.6.0程序的配置（带有spark功能）】

```
[eshore@bigdatamgr1 hadoop]$ ll
-rw-r--r-- 1 eshore biadmin   935 Jun  9 16:24 core-site.xml
-rw-r--r-- 1 eshore biadmin  3670 Jun  8 22:14 hadoop-env.cmd
-rwxr-xr-x 1 eshore biadmin  3609 Jun  9 12:06 hadoop-env.sh
lrwxrwxrwx 1 eshore biadmin    51 Jun  9 12:07 hdfs-site.xml -> /data/opt/ibm/biginsights/hadoop-conf/hdfs-site.xml
-rwxr-xr-x 1 eshore biadmin  1383 Jun  9 12:06 mapred-env.sh
lrwxrwxrwx 1 eshore biadmin    44 Jun  9 12:07 slaves -> /data/opt/ibm/biginsights/hadoop-conf/slaves
-rwxr-xr-x 1 eshore biadmin  4145 Jun  9 20:29 yarn-env.sh
-rw-r--r-- 1 eshore biadmin  2109 Jun 11 12:16 yarn-site.xml
...

[eshore@bigdatamgr1 hadoop]$ 

[eshore@bigdatamgr1 hadoop]$ xsltproc format.xslt core-site.xml 
fs.defaultFS=hdfs://bi-00-01.bi.domain.com:9000
hadoop.tmp.dir=/data/var/ibm/biginsights/hadoop/tmp/${user.name}
hadoop.http.staticuser.user=eshore
hadoop.user.group.static.mapping.overrides=eshore:biadmin

[eshore@bigdatamgr1 hadoop]$ xsltproc format.xslt yarn-site.xml 
yarn.nodemanager.aux-services=mapreduce_shuffle,spark_shuffle
yarn.nodemanager.aux-services.mapreduce_shuffle.class=org.apache.hadoop.mapred.ShuffleHandler
yarn.nodemanager.aux-services.spark_shuffle.class=org.apache.spark.network.yarn.YarnShuffleService #spark-dynamic要用到
yarn.resourcemanager.address=bi-00-01.bi.domain.com:8032
yarn.resourcemanager.scheduler.address=bi-00-01.bi.domain.com:8030
yarn.resourcemanager.resource-tracker.address=bi-00-01.bi.domain.com:8031
yarn.resourcemanager.admin.address=bi-00-01.bi.domain.com:8033
yarn.resourcemanager.webapp.address=bi-00-01.bi.domain.com:8088 #不能用0.0.0.0。2.4改进版本，ApplicationMaster Tracking URL会使用该地址重定向到任务执行状态页面
yarn.nodemanager.resource.memory-mb=32768
yarn.scheduler.minimum-allocation-mb=2048
yarn.scheduler.maximum-allocation-mb=32768
```
{% endcomment %}
