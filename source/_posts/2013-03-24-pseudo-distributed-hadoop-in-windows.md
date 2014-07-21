---
layout: post
title: "windows配置hadoop伪分布式环境(续)"
date: 2013-03-24 01-14
comments: true
categories: [hadoop]
---

在前一篇文章中，介绍了一写常见问题的解决方法。

但是，当我重装系统，再次按照[前面一篇文章]({% post_url 2012-11-25-windows-install-pseudo-distributed-hadoop1 %})  **安装cygwin和hadoop-1**时，发现伪分布式环境使用mapred时，总是报错。（忘了，但是好像当时没有遇到过这种情况。就当是安装win8送给自己的礼物吧！）。

怀疑了很多东西，配置有问题，重新自定hadoop.tmp.dir，把hadoop-1.1.0换成hadoop-1.0.0等等。

错误日志如下：

```
$ hhadoop fs -rmr /test/output ; hhadoop jar hadoop-examples-1.0.0.jar wordcount /test/input /test/output
Deleted hdfs://WINSE:9000/test/output
13/03/23 22:46:07 INFO input.FileInputFormat: Total input paths to process : 1
13/03/23 22:46:08 INFO mapred.JobClient: Running job: job_201303232144_0002
13/03/23 22:46:09 INFO mapred.JobClient:  map 0% reduce 0%
13/03/23 22:46:16 INFO mapred.JobClient: Task Id : attempt_201303232144_0002_m_000002_0, Status : FAILED
java.lang.Throwable: Child Error
        at org.apache.hadoop.mapred.TaskRunner.run(TaskRunner.java:272)
Caused by: java.io.IOException: Task process exit with nonzero status of -1.
        at org.apache.hadoop.mapred.TaskRunner.run(TaskRunner.java:259)

13/03/23 22:46:16 WARN mapred.JobClient: Error reading task outputhttp://WINSE:50060/tasklog?plaintext=true&attemptid=attempt_201303232144_0002_m_000002_0&filter=stdout
13/03/23 22:46:16 WARN mapred.JobClient: Error reading task outputhttp://WINSE:50060/tasklog?plaintext=true&attemptid=attempt_201303232144_0002_m_000002_0&filter=stderr
13/03/23 22:46:22 INFO mapred.JobClient: Task Id : attempt_201303232144_0002_m_000002_1, Status : FAILED
```

经过不断的修改源码，加入sysout打印，算是最终找出程序出现错误的地方！

org.apache.hadoop.mapred.DefaultTaskController.java #launchTask
org.apache.hadoop.mapred.JvmManager.java #runChild
org.apache.hadoop.mapred.TaskRunner.java #launchJvmAndWait

org.apache.hadoop.fs.FileUtil.java #checkReturnValue
org.apache.hadoop.fs.RawLocalFileSystem.java  #setPermission  #mkdirs

发现在org.apache.hadoop.fs.RawLocalFileSystem.mkdirs(Path)方法中，建立文件的路径方法检查attempt_201303232144_0002_m_000001_0**是否为文件夹**时会失败！

而在cygwin中查看文件属性：

```
Winseliu@WINSE ~/hadoop/logs/userlogs/job_201303232144_0002
$ ll
总用量 9
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000001_0 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000001_0
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000001_1 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000001_1
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000001_2 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000001_2
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000001_3 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000001_3
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000002_0 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000002_0
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000002_1 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000002_1
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000002_2 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000002_2
lrwxrwxrwx 1 Winseliu None  89 3月  23 22:46 attempt_201303232144_0002_m_000002_3 -> /cluster/mapred/local/userlogs/job_201303232144_0002/attempt_201303232144_0002_m_000002_3
-rwxr-xr-x 1 Winseliu None 404 3月  23 22:46 job-acls.xml
```

对于linux来说，这些就是引用到另一个文件夹，它本身应该也是文件夹！但是window的jdk不认识这些东西！

```
  public boolean mkdirs(Path f) throws IOException {
    Path parent = f.getParent();
    File p2f = pathToFile(f);
    return (parent == null || mkdirs(parent)) &&
      (p2f.mkdir() || p2f.isDirectory());
  }
```

所以在判断p2f.isDirectory()返回false，然后会抛出IOException，最终以-1的状态退出Map Child的程序！

其使用org.apache.hadoop.mapred.TaskRunner.prepareLogFiles(TaskAttemptID, boolean)方法来指定输出日志的位置。在最终执行的会在shell命令中把sysout和syserr输出到日志文件中（ $COMMAND  1>>$stdout  2>>$stderr ，本文最后有贴运行时的cmd）。

而userlogs的父目录是使用hadoop.log.dir系统属性来进行配置的！

mapred.DefaultTaskController.launchTask()

|--mapred.TaskLog.buildCommandLine()

## 临时解决方法：

把hadoop.log.dir定位到真正mapred日志的目录( mapred.local.dir : ${hadoop.tmp.dir}/mapred/local )！

```
export HADOOP_LOG_DIR=/cluster/mapred/local
```

最终的效果，运行的程序会把日志输出到attempt目录下的stdout,stderr文件中。

```
Winseliu@WINSE /cluster/mapred/local/userlogs/job_201303240035_0001/attempt_201303240035_0001_m_000000_0
$ ll
总用量 6
lrwxrwxrwx  1 Winseliu None   89 3月  24 00:36 attempt_201303240035_0001_m_000000_0 -> /cluster/mapred/local/userlogs/job_201303240035_0001/attempt_201303240035_0001_m_000000_0
----------+ 1 Winseliu None  136 3月  24 00:36 log.index
-rw-r--r--+ 1 Winseliu None    0 3月  24 00:36 stderr
-rw-r--r--+ 1 Winseliu None    0 3月  24 00:36 stdout
----------+ 1 Winseliu None 1238 3月  24 00:36 syslog
```

上面的软链接是调用org.apache.hadoop.mapred.TaskLog.createTaskAttemptLogDir()生成的，本文最后有贴运行时ln命令及参数。

ln当linkname是一个已经存在文件夹时，会在linkname的文件夹下建立一个以targetname作为名称的链接。

```
Winseliu@WINSE ~/tt
$ mkdir f1

Winseliu@WINSE ~/tt
$ ln -s f1 f1

Winseliu@WINSE ~/tt
$ ls -Rl
.:
总用量 0
drwxr-xr-x+ 1 Winseliu None 0 3月  24 13:56 f1

./f1:
总用量 1
lrwxrwxrwx 1 Winseliu None 2 3月  24 13:56 f1 -> f1

```

把windows的/cluster映射到cygwin(linux)的/cluster:

```
Winseliu@WINSE ~/hadoop
$ ll /cygdrive/c | grep cluster
drwxr-xr-x+ 1 Winseliu         None                      0 3月  24 00:08 cluster

Winseliu@WINSE ~/hadoop
$ ll / | grep cluster
lrwxrwxrwx   1 Winseliu None     19 3月  23 09:39 cluster -> /cygdrive/c/cluster
```

但是，运行wordcount的例子时，还是不正常！查看tasktracker的日志时，发现有String转成Integer的NumberFormatException异常!

修改org.apache.hadoop.mapred.JvmManager.JvmManagerForType.**JvmRunner**.kill()方法。添加pidStr为空字符串的检查！

```
String pidStr = jvmIdToPid.get(jvmId);
if (pidStr != null && !pidStr.isEmpty()) {
```

然后，终于看到Finish咯！在/test/output/part-r-00000中也看到了结果。

## 其他一些简化处理，即配置文件：

```
alias startCluster="~/hadoop/bin/start-all.sh"
alias stopCluster="~/hadoop/bin/stop-all.sh; ~/hadoop/bin/stop-all.sh"

alias hhadoop="~/hadoop/bin/hadoop"

Winseliu@WINSE ~
$ ll | grep hadoop
lrwxrwxrwx  1 Winseliu None    12 3月  23 10:44 hadoop -> hadoop-1.0.0
drwx------+ 1 Winseliu None     0 3月  24 00:06 hadoop-1.0.0
```

配置文件：

```
	<!-- core-site.xml -->

	<configuration>

	<property>
	<name>fs.default.name</name>
	<value>hdfs://WINSE:9000</value>
	</property>

	<property>
	<name>hadoop.tmp.dir</name>
	<value>/cluster</value>
	</property>

	</configuration>

	<!-- hdfs-site.xml -->

	<configuration>

	<property>
	<name>dfs.replication</name>
	<value>1</value>
	</property>

	<property>
	  <name>dfs.permissions</name>
	  <value>false</value>
	</property>

	<property>
	  <name>dfs.permissions.supergroup</name>
	  <value>None</value>
	</property>

	<property>
	<name>dfs.safemode.extension</name>
	<value>1000</value>
	</property>

	</configuration>

	<!-- mapred-site.xml -->

	<configuration>

	<property>
	<name>mapred.job.tracker</name>
	<value>WINSE:9001</value>
	</property>

	</configuration>
```

关于查看启动的进程，看可以通过任务管理器来查看：

![](http://dl.iteye.com/upload/attachment/0082/1102/e0e310ee-731c-37c3-8e74-30e425d374f5.png)

还可以看看pid的修改时间，来确认服务的启动：
![](http://dl.iteye.com/upload/attachment/0082/2365/d6277aa6-8821-354a-831a-b9b518272b10.png)

我是经常通过50070和50030来查看的~~ 看到50030的Nodes为1时，就说明集群启动正常了。

 执行时的日志：

```
cmd : ln -s /cluster/mapred/local\userlogs\job_201303241340_0001\attempt_201303241340_0001_m_000000_0 C:\cluster\mapred\local\userlogs\job_201303241340_0001\attempt_201303241340_0001_m_000000_0

cmdLine : export HADOOP_CLIENT_OPTS="-Dhadoop.tasklog.taskid=attempt_201303241340_0001_m_000000_0 -Dhadoop.tasklog.iscleanup=false -Dhadoop.tasklog.totalLogFileSize=0"
export SHELL="/bin/bash"
export HADOOP_WORK_DIR="\cluster\mapred\local\taskTracker\Winseliu\jobcache\job_201303241340_0001\attempt_201303241340_0001_m_000000_0\work"
export HOME="/homes/"
export LOGNAME="Winseliu"
export HADOOP_TOKEN_FILE_LOCATION="/cluster/mapred/local/taskTracker/Winseliu/jobcache/job_201303241340_0001/jobToken"
export HADOOP_ROOT_LOGGER="INFO,TLA"
export LD_LIBRARY_PATH="\cluster\mapred\local\taskTracker\Winseliu\jobcache\job_201303241340_0001\attempt_201303241340_0001_m_000000_0\work"
export USER="Winseliu"

exec '/cygdrive/c/Java/jdk1.7.0_02/jre/bin/java' '-Djava.library.path=/home/Winseliu/hadoop-1.0.0/lib/native/Windows_NT_unknown-x86-32;\cluster\mapred\local\
taskTracker\Winseliu\jobcache\job_201303241340_0001\attempt_201303241340_0001_m_000000_0\work' '-Xmx200m' '-Djava.net.preferIPv4Stack=true' '-Dhadoop.metrics
.log.level=WARN' '-Djava.io.tmpdir=/cluster/mapred/local/taskTracker/Winseliu/jobcache/job_201303241340_0001/attempt_201303241340_0001_m_000000_0/work/tmp' '
-classpath' 'C:\cygwin\home\Winseliu\conf;C:\Java\jdk1.7.0_02\lib\tools.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\;C:\cygwin\home\Winseliu\hadoop-1.0.0\hadoop
-core-1.0.0.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\asm-3.2.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\aspectjrt-1.6.5.jar;C:\cygwin\home\Winseliu\had
oop-1.0.0\lib\aspectjtools-1.6.5.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-beanutils-1.7.0.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-be
anutils-core-1.8.0.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-cli-1.2.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-codec-1.4.jar;C:\cygwin\
home\Winseliu\hadoop-1.0.0\lib\commons-collections-3.2.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-configuration-1.6.jar;C:\cygwin\home\Winseliu\h
adoop-1.0.0\lib\commons-daemon-1.0.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-digester-1.8.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-e
l-1.0.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-httpclient-3.0.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-lang-2.4.jar;C:\cygwin\home\
Winseliu\hadoop-1.0.0\lib\commons-logging-1.1.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-logging-api-1.0.4.jar;C:\cygwin\home\Winseliu\hadoop-1.0
.0\lib\commons-math-2.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\commons-net-1.4.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\core-3.1.1.jar;C:\cygwin\
home\Winseliu\hadoop-1.0.0\lib\hadoop-capacity-scheduler-1.0.0.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\hadoop-fairscheduler-1.0.0.jar;C:\cygwin\home\Win
seliu\hadoop-1.0.0\lib\hadoop-thriftfs-1.0.0.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\hsqldb-1.8.0.10.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jackso
n-core-asl-1.0.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jackson-mapper-asl-1.0.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jasper-compiler-5.5.12.ja
r;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jasper-runtime-5.5.12.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jdeb-0.8.jar;C:\cygwin\home\Winseliu\hadoop-1.0
.0\lib\jersey-core-1.8.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jersey-json-1.8.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jersey-server-1.8.jar;C:\cyg
win\home\Winseliu\hadoop-1.0.0\lib\jets3t-0.6.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jetty-6.1.26.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jetty-
util-6.1.26.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jsch-0.1.42.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\junit-4.5.jar;C:\cygwin\home\Winseliu\hadoo
p-1.0.0\lib\kfs-0.2.2.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\log4j-1.2.15.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\mockito-all-1.8.5.jar;C:\cygwin\
home\Winseliu\hadoop-1.0.0\lib\mysql-connector-java-5.1.10-bin.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\ojdbc6.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\l
ib\oro-2.0.8.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\servlet-api-2.5-20081211.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\slf4j-api-1.4.3.jar;C:\cygwin
\home\Winseliu\hadoop-1.0.0\lib\slf4j-log4j12-1.4.3.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\sqoop-1.4.1-incubating.jar;C:\cygwin\home\Winseliu\hadoop-1.
0.0\lib\xmlenc-0.52.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jsp-2.1\jsp-2.1.jar;C:\cygwin\home\Winseliu\hadoop-1.0.0\lib\jsp-2.1\jsp-api-2.1.jar;\cluste
r\mapred\local\taskTracker\Winseliu\jobcache\job_201303241340_0001\jars\classes;\cluster\mapred\local\taskTracker\Winseliu\jobcache\job_201303241340_0001\jar
s;\cluster\mapred\local\taskTracker\Winseliu\jobcache\job_201303241340_0001\attempt_201303241340_0001_m_000000_0\work' '-Dhadoop.log.dir=C:\cluster\mapred\lo
cal' '-Dhadoop.root.logger=INFO,TLA' '-Dhadoop.tasklog.taskid=attempt_201303241340_0001_m_000000_0' '-Dhadoop.tasklog.iscleanup=false' '-Dhadoop.tasklog.tota
lLogFileSize=0' 'org.apache.hadoop.mapred.Child' '127.0.0.1' '49203' 'attempt_201303241340_0001_m_000000_0' 'C:\cluster\mapred\local\userlogs\job_20130324134
0_0001\attempt_201303241340_0001_m_000000_0' '-1682417583'  < /dev/null  1>> /cygdrive/c/cluster/mapred/local/userlogs/job_201303241340_0001/attempt_20130324
1340_0001_m_000000_0/stdout 2>> /cygdrive/c/cluster/mapred/local/userlogs/job_201303241340_0001/attempt_201303241340_0001_m_000000_0/stderr
```

linux的版本的日志目录结构：

![](http://dl.iteye.com/upload/attachment/0082/1222/e1eeb8b1-cc16-3439-bc0f-2758e283012a.png)

  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1835591)
