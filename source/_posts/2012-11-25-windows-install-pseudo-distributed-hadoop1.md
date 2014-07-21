---
layout: post
title: "windows配置hadoop1的伪分布式环境"
date: 2012-11-25 14-26
comments: true
categories: [hadoop]
---

由于Hadoop的部分操作需要用到Linux的shell命令，所以在Windows下安装，需要安装一个Linux的运行时环境。然后，需要配置无密钥通信协议。配置完后，需要配置Hadoop的xml文件。

# 安装Cygwin

[http://cygwin.com/install.html](http://cygwin.com/install.html)

## Cygwin中配置sshd

[http://docs.oracle.com/cd/E24628_01/install.121/e22624/preinstall_req_cygwin_ssh.htm#CBHIAFGI](http://docs.oracle.com/cd/E24628_01/install.121/e22624/preinstall_req_cygwin_ssh.htm#CBHIAFGI)

## 伪分布式配置

配置文档路径： hadoop-1.1.0/docs/single_node_setup.html

```
bin/hadoop namenode -format

bin/start-all.sh
bin/stop-all.sh

http://localhost:50030
http://localhost:50070
```

## 遇到的问题及解决：

在真正运行的时刻会遇到几个问题:

1、设置的路径并非使用cygwin linux的路径。

hadoop.tmp.dir在/tmp目录下面，理论上应该在C:\cygwin\tmp，但实际的路径确实C:\tmp

路径不同意，我们就设置自己的目录就可以了

```
     <property>
         <name>hadoop.tmp.dir</name>
         <value>/cygwin/home/Winseliu/cloud</value>
     </property>
```

2、启动datanode和jobtracker，以及tasktacker时会有路径权限的问题

```
2012-11-25 13:53:05,031 ERROR org.apache.hadoop.security.UserGroupInformation: PriviledgedActionException as:Winseliu cause:java.io.IOException: Failed to set permissions of path: C:\cygwin\home\Winseliu\hadoop-1.1.0\logs\history to 0755
2012-11-25 13:53:05,032 FATAL org.apache.hadoop.mapred.JobTracker: java.io.IOException: Failed to set permissions of path: C:\cygwin\home\Winseliu\hadoop-1.1.0\logs\history to 0755
        at org.apache.hadoop.fs.FileUtil.checkReturnValue(FileUtil.java:689)
        at org.apache.hadoop.fs.FileUtil.setPermission(FileUtil.java:670)
        at org.apache.hadoop.fs.RawLocalFileSystem.setPermission(RawLocalFileSystem.java:509)
        at org.apache.hadoop.fs.RawLocalFileSystem.mkdirs(RawLocalFileSystem.java:344)
        at org.apache.hadoop.fs.FilterFileSystem.mkdirs(FilterFileSystem.java:189)
        at org.apache.hadoop.mapred.JobHistory.init(JobHistory.java:510)
...
...
2012-11-25 13:53:04,389 INFO org.apache.hadoop.mapred.TaskTracker: Good mapred local directories are: /cygwin/home/Winseliu/cloud/mapred/local
2012-11-25 13:53:04,396 ERROR org.apache.hadoop.mapred.TaskTracker: Can not start task tracker because java.io.IOException: Failed to set permissions of path: \cygwin\home\Winseliu\cloud\mapred\local\taskTracker to 0755
        at org.apache.hadoop.fs.FileUtil.checkReturnValue(FileUtil.java:689)
        at org.apache.hadoop.fs.FileUtil.setPermission(FileUtil.java:670)

```

权限问题，直接修改FileUtils的checkReturnValue()方法，替换hadoop-core-1.1.0.jar中的FileUtils.class文件

```
	private static void checkReturnValue(boolean rv, File p, 
									   FsPermission permission
									   ) throws IOException {
	if (!rv) {
		// FIXME
			try {
				throw new IOException("Failed to set permissions of path: " + p
						+ " to " + String.format("%04o", permission.toShort()));
			} catch (Exception e) {
				e.printStackTrace();
			}
	}
	}
```

3、使用jps查不全真正执行的java进程，不知道那个进程启动或未启动

```
Winseliu@WINSE ~/hadoop-1.1.0
$ jps
6364 NameNode
7168 JobTracker
2692 Jps

Winseliu@WINSE ~/hadoop-1.1.0
$ ps aux | grep java
     7880       1    5544       7028  ?       1001 13:20:40 /cygdrive/c/Java/jdk1.7.0_02/bin/java
     5968       1    7500       4592  ?       1001 13:20:36 /cygdrive/c/Java/jdk1.7.0_02/bin/java
     5784       1     484       6364  pty0    1001 13:20:31 /cygdrive/c/Java/jdk1.7.0_02/bin/java
     6732       1     484       7168  pty0    1001 13:20:38 /cygdrive/c/Java/jdk1.7.0_02/bin/java
     7976       1    5716       5628  ?       1001 13:20:34 /cygdrive/c/Java/jdk1.7.0_02/bin/java
     4492       0       0       4492  pty0    1001   Jan  1 /cygdrive/c/Java/jdk1.7.0_02/bin/java

```

直接再执行一次start-all.sh，如果会提示让你先stop就说明该进程已经启动了。

```
Winseliu@WINSE ~
$ cd hadoop-1.1.0/

Winseliu@WINSE ~/hadoop-1.1.0
$ bin/start-all.sh
starting namenode, logging to /home/Winseliu/hadoop-1.1.0/libexec/../logs/hadoop-Winseliu-namenode-WINSE.out
localhost: starting datanode, logging to /home/Winseliu/hadoop-1.1.0/libexec/../logs/hadoop-Winseliu-datanode-WINSE.out
localhost: starting secondarynamenode, logging to /home/Winseliu/hadoop-1.1.0/libexec/../logs/hadoop-Winseliu-secondarynamenode-WINSE.out
starting jobtracker, logging to /home/Winseliu/hadoop-1.1.0/libexec/../logs/hadoop-Winseliu-jobtracker-WINSE.out
localhost: starting tasktracker, logging to /home/Winseliu/hadoop-1.1.0/libexec/../logs/hadoop-Winseliu-tasktracker-WINSE.out

Winseliu@WINSE ~/hadoop-1.1.0
$ bin/start-all.sh
namenode running as process 2648\. Stop it first.
localhost: datanode running as process 3512\. Stop it first.
localhost: secondarynamenode running as process 2468\. Stop it first.
jobtracker running as process 2388\. Stop it first.
localhost: tasktracker running as process 860\. Stop it first.

Winseliu@WINSE ~/hadoop-1.1.0
$

```

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1734737)
