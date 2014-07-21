---
layout: post
title: 远程调试hadoop2以及错误处理方法
date: 2014-4-21 22:47:48
categories: [hadoop, debug]
---

了解程序运行过程，除了一行行代码的扫射源代码。更快捷的方式是运行调试源码，通过F6/F7来一步步的带领我们熟悉程序。针对特定细节具体数据，打个断点调试则是水到渠成的方式。

## Java远程调试

```
 * JDK 1.3 or earlier -Xnoagent -Djava.compiler=NONE -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=6006
 * JDK 1.4(linux ok) -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=6006
 * newer JDK(win7 & jdk7) -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=6006
```

## 同一操作系统任务提交

windows提交到windows，linux提交到linux，可以直接通过命令行添加参数调试wordcount任务：

```
E:\local\dotfile>hdfs dfs -rmr /out # native-lib放在非path路径下，cmd脚本中有对其进行处理

E:\local\dotfile>hadoop org.apache.hadoop.examples.WordCount  "-Dmapreduce.map.java.opts=-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8090 -Djava.library.path=E:\local\libs\big\hadoop-2.2.0\lib\native -Dmapreduce.reduce.java.opts=-Djava.library.path=E:\local\libs\big\hadoop-2.2.0\lib\native"  /in /out
```

**suspend设置为y，会等待客户端连接再运行**。在eclipse中在WordCount$TokenizerMapper#map打个断点，然后再使用`Remote Java Application`就可以调试程序了。

## Hadoop集群环境下调试任务

hadoop有很多的程序，同样有对应的环境变量选项来进行设置！

* 主程序-调试Job提交
	* `set HADOOP_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8090"`
	* 可以在配置文件中进行设置。需要注意可能会覆盖已经设置的该参数的值。
* Nodemanager调试
	* `set HADOOP_NODEMANAGER_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8092"`
	* (linux下需要定义在文件中)`YARN_NODEMANAGER_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8092"`
* ResourceManager调试
	* HADOOP_RESOURCEMANAGER_OPTS
	* `export YARN_RESOURCEMANAGER_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8091"`

Linux上的设置略有不同，通过SSH再调用的进程(如NodeManager)需要把其OPTS写到命令行脚本文件中！！
linux需要远程调试NodeManager的话，需要写到etc/hadoop/yarn-env.sh文件中！不然，nodemanger不生效（通过ssh去执行的）！

### 其他调试技巧

调试测试集群环境，比本地windows开发环境复杂点。毕竟本地windows的就一个主一个从。而把**任务放到分布式集群**上时，例如调试分布式缓存的！
那么就需要一些小技巧来获取任务运行所在的机器！下面的步骤中有具体操作命令。

### 任务配置及运行

eclipse下windows提交job到linux的补丁，查阅[[MAPREDUCE-5655]](https://issues.apache.org/jira/browse/MAPREDUCE-5655)

```
# 配置
	<property>
		<name>mapred.remote.os</name>
		<value>Linux</value>
	</property>
	<property>
		<name>mapreduce.job.jar</name>
		<value>dta-analyser-all.jar</value>
	</property>

	<property>
		<name>mapreduce.map.java.opts</name>
		<value>-Xmx1024m -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090</value>
	</property>

	<property>
		<name>mapred.task.timeout</name>
		<value>1800000</value>
	</property>

# 代码，map/reduce数都设置为1	
job.setNumReduceTasks(1);
job.getConfiguration().setInt(MRJobConfig.NUM_MAPS, 1);

```		

* 调试的时刻把超时时间设置的久一点，否则：

```
 Got exception: java.net.SocketTimeoutException: Call From winseliu/127.0.0.1 to winse.com:2850 failed on socket timeout exception: java.net.SocketTimeoutException: 60000 millis timeout while waiting for channel to be ready for read. ch :
```

* 调试main方法参数设置

调试main（转瞬即逝的把suspend设置为true！），map的调试选项的语句写在配置文件里面

```
export HADOOP_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8073"

Administrator@winseliu ~/hadoop
$ sh -x bin/hadoop org.apache.hadoop.examples.WordCount /in /out 
```

### 遍历所有子节点，查找节点运行map程序的信息

map调试的端口配置为18090，根据这个选项来查找程序运行的机器。

```
[hadoop@umcc97-44 ~]$ for h in `cat hadoop-2.2.0/etc/hadoop/slaves` ; do ssh $h 'ps aux|grep java | grep 18090'; echo $h;  done
hadoop    8667  0.0  0.0  63888  1268 ?        Ss   18:21   0:00 bash -c ps aux|grep java | grep 18090
umcc97-142
hadoop   12686  0.0  0.0  63868  1260 ?        Ss   18:21   0:00 bash -c ps aux|grep java | grep 18090
umcc97-143
hadoop   23516  0.0  0.0  63856  1108 ?        Ss   18:11   0:00 /bin/bash -c /home/java/jdk1.7.0_45/bin/java -Djava.net.preferIPv4Stack=true -Dhadoop.metrics.log.level=WARN  -Xmx256m -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090 -Djava.io.tmpdir=/home/hadoop/hadoop-2.2.0/tmp/nm-local-dir/usercache/hadoop/appcache/application_1397006359464_1605/container_1397006359464_1605_01_000002/tmp -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1605/container_1397006359464_1605_01_000002 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA org.apache.hadoop.mapred.YarnChild 10.18.97.143 57576 attempt_1397006359464_1605_m_000000_0 2 1>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1605/container_1397006359464_1605_01_000002/stdout 2>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1605/container_1397006359464_1605_01_000002/stderr 
hadoop   23522  0.0  0.0 605136 15728 ?        Sl   18:11   0:00 /home/java/jdk1.7.0_45/bin/java -Djava.net.preferIPv4Stack=true -Dhadoop.metrics.log.level=WARN -Xmx256m -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090 -Djava.io.tmpdir=/home/hadoop/hadoop-2.2.0/tmp/nm-local-dir/usercache/hadoop/appcache/application_1397006359464_1605/container_1397006359464_1605_01_000002/tmp -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1605/container_1397006359464_1605_01_000002 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA org.apache.hadoop.mapred.YarnChild 10.18.97.143 57576 attempt_1397006359464_1605_m_000000_0 2
hadoop   23665  0.0  0.0  63856  1264 ?        Ss   18:21   0:00 bash -c ps aux|grep java | grep 18090
umcc97-144
```

仅打印运行map的节点名称

```
[hadoop@umcc97-44 ~]$ for h in `cat hadoop-2.2.0/etc/hadoop/slaves` ; do ssh $h 'if ps aux|grep -v grep | grep java | grep 18090 | grep -v bash 2>&1 1>/dev/null ; then echo `hostname`; fi'; done
umcc97-142
[hadoop@umcc97-44 ~]$ 
```

后面的操作就和普通的java程序调试步骤一样了。不再赘述。

## 任务运行过程中的数据

#### 辅助运行的两个bash程序

运行的第一个程序（000001）为AppMaster，第二程序（000002）才是我们提交job的map任务。

```
[hadoop@umcc97-143 ~]$ cd hadoop-2.2.0/tmp/nm-local-dir/nmPrivate
[hadoop@umcc97-143 nmPrivate]$ ls -Rl
.:
total 12
drwxrwxr-x 4 hadoop hadoop 4096 Apr 21 18:34 application_1397006359464_1606
-rw-rw-r-- 1 hadoop hadoop    6 Apr 21 18:34 container_1397006359464_1606_01_000001.pid
-rw-rw-r-- 1 hadoop hadoop    6 Apr 21 18:34 container_1397006359464_1606_01_000002.pid

./application_1397006359464_1606:
total 8
drwxrwxr-x 2 hadoop hadoop 4096 Apr 21 18:34 container_1397006359464_1606_01_000001
drwxrwxr-x 2 hadoop hadoop 4096 Apr 21 18:34 container_1397006359464_1606_01_000002

./application_1397006359464_1606/container_1397006359464_1606_01_000001:
total 8
-rw-r--r-- 1 hadoop hadoop   95 Apr 21 18:34 container_1397006359464_1606_01_000001.tokens
-rw-r--r-- 1 hadoop hadoop 3121 Apr 21 18:34 launch_container.sh

./application_1397006359464_1606/container_1397006359464_1606_01_000002:
total 8
-rw-r--r-- 1 hadoop hadoop  129 Apr 21 18:34 container_1397006359464_1606_01_000002.tokens
-rw-r--r-- 1 hadoop hadoop 3532 Apr 21 18:34 launch_container.sh
[hadoop@umcc97-143 nmPrivate]$ 
[hadoop@umcc97-143 nmPrivate]$ jps
4692 NodeManager
4173 DataNode
13497 YarnChild
7538 HRegionServer
13376 MRAppMaster
13574 Jps
[hadoop@umcc97-143 nmPrivate]$ cat *.pid
13366
13491
[hadoop@umcc97-143 nmPrivate]$ ps aux | grep 13366
hadoop   13366  0.0  0.0  63868  1088 ?        Ss   18:34   0:00 /bin/bash -c /home/java/jdk1.7.0_45/bin/java -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1606/container_1397006359464_1606_01_000001 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA  -Xmx1024m org.apache.hadoop.mapreduce.v2.app.MRAppMaster 1>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1606/container_1397006359464_1606_01_000001/stdout 2>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1606/container_1397006359464_1606_01_000001/stderr 
hadoop   13594  0.0  0.0  61204   760 pts/2    S+   18:36   0:00 grep 13366
[hadoop@umcc97-143 nmPrivate]$ ps aux | grep 13491
hadoop   13491  0.0  0.0  63868  1100 ?        Ss   18:34   0:00 /bin/bash -c /home/java/jdk1.7.0_45/bin/java -Djava.net.preferIPv4Stack=true -Dhadoop.metrics.log.level=WARN  -Xmx256m -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090 -Djava.io.tmpdir=/home/hadoop/hadoop-2.2.0/tmp/nm-local-dir/usercache/hadoop/appcache/application_1397006359464_1606/container_1397006359464_1606_01_000002/tmp -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1606/container_1397006359464_1606_01_000002 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA org.apache.hadoop.mapred.YarnChild 10.18.97.143 52046 attempt_1397006359464_1606_m_000000_0 2 1>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1606/container_1397006359464_1606_01_000002/stdout 2>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1397006359464_1606/container_1397006359464_1606_01_000002/stderr 
hadoop   13599  0.0  0.0  61204   760 pts/2    S+   18:37   0:00 grep 13491
[hadoop@umcc97-143 nmPrivate]$ 
```

#### 程序运行本地缓存数据

```
[hadoop@umcc97-143 container_1397006359464_1606_01_000002]$ ls -l
total 28
-rw-r--r-- 1 hadoop hadoop  129 Apr 21 18:34 container_tokens
-rwx------ 1 hadoop hadoop  516 Apr 21 18:34 default_container_executor.sh
lrwxrwxrwx 1 hadoop hadoop   65 Apr 21 18:34 filter.io -> /home/hadoop/hadoop-2.2.0/tmp/nm-local-dir/filecache/10/filter.io
lrwxrwxrwx 1 hadoop hadoop  120 Apr 21 18:34 job.jar -> /home/hadoop/hadoop-2.2.0/tmp/nm-local-dir/usercache/hadoop/appcache/application_1397006359464_1606/filecache/10/job.jar
lrwxrwxrwx 1 hadoop hadoop  120 Apr 21 18:34 job.xml -> /home/hadoop/hadoop-2.2.0/tmp/nm-local-dir/usercache/hadoop/appcache/application_1397006359464_1606/filecache/13/job.xml
-rwx------ 1 hadoop hadoop 3532 Apr 21 18:34 launch_container.sh
drwx--x--- 2 hadoop hadoop 4096 Apr 21 18:34 tmp
[hadoop@umcc97-143 container_1397006359464_1606_01_000002]$ 
```

## 处理问题方法

* 打印DEBUG日志：`export HADOOP_ROOT_LOGGER=DEBUG,console`
	* 日志文件放置在nodemanager节点的logs/userlogs目录下。
* 打印DEBUG日志也搞不定时，可以在源码里面sysout信息然后把**class覆盖**，来进行定位配置的问题。
* 如果不清楚shell的执行过程，可以通过`sh -x [CMD]`，或者在脚本文件的操作前加上`set -x`。相当于windows-batch的`echo on`功能。

## 参考

* [remote debugger opts](http://stackoverflow.com/questions/975271/remote-debugging-a-java-application)

