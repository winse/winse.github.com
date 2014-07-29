---
layout: post
title: "hadoop安全的关闭datanode节点"
date: 2014-07-29 15:08:41 +0800
comments: true
categories: [hadoop]
---

hadoop默认就有冗余（dfs.replication）的机制，所以一般情况下，一台机器挂了也没所谓。集群会自动的进行复制均衡处理。

作为测试，如果dfs.replication设置为1的情况下，怎么安全的把datanode节点服务关闭呢？例如说，刚刚开始搭建环境是把namenode、datanode放在一台机器上，后面增加了机器如何把datanode分离出来呢？

借助于**dfs.hosts.exclude**即可完成顺序的完成此项任务。

修改hdfs-site.xml配置。我操作的时刻仅修改了master1上的hdfs-site.xml。把**master1**值写入到对应的文件中。

```
	[hadoop@master1 hadoop]$ cat hdfs-site.xml 
	...
	<property>
	        <name>dfs.hosts.exclude</name>
	        <value>/home/hadoop/hadoop-2.2.0/etc/hadoop/exclude</value>
	</property>

	</configuration>
	[hadoop@master1 hadoop]$ cat /home/hadoop/hadoop-2.2.0/etc/hadoop/exclude
	master1

```

修改完成后，刷新节点即可(完全没有必要重启集dfs)。

```
hadoop dfsadmin -refreshNodes
```

可以通过`dfsadmin -report`或者网页查看master1已经变成*Decommission In Progress*了。

![](http://file.bmob.cn/M00/05/4C/wKhkA1PXUMOAVvvWAAED6CN-3Rg187.png)

注：

问题一： 在新建节点是slaver1的防火墙没关闭，由于master1已经被exclude，而slaver1不能提供服务，上传文件时报错：

```
[hadoop@master1 hadoop]$ hadoop fs -put slaves  /
14/07/29 15:18:21 WARN hdfs.DFSClient: DataStreamer Exception
org.apache.hadoop.ipc.RemoteException(java.io.IOException): File /slaves._COPYING_ could only be replicated to 0 nodes instead of minReplication (=1).  There are 2 datanode(s) running and no node(s) are excluded in this operation.
        at org.apache.hadoop.hdfs.server.blockmanagement.BlockManager.chooseTarget(BlockManager.java:1384)
        at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getAdditionalBlock(FSNamesystem.java:2477)
```

关闭防火墙一样再次上传，还是报同样的错误。此时，也可以通过刷新节点`hadoop dfsadmin -refreshNodes`来解决。 

问题二： 设置备份数量

```
[hadoop@master1 hadoop]$ hadoop fs -setrep 3 /slaves 
Replication 3 set: /slaves
``` 

问题三： 新增节点

拷贝程序到新增节点，然后启动

```
[hadoop@master1 ~]$ tar zc hadoop-2.2.0 --exclude=logs | ssh slaver2 'cat | tar zx'

[hadoop@slaver2 ~]$ cd hadoop-2.2.0/
[hadoop@slaver2 hadoop-2.2.0]$ sbin/hadoop-daemon.sh start datanode
```

也可以修改master上的slavers文件再`sbin/start-dfs.sh`启动。
