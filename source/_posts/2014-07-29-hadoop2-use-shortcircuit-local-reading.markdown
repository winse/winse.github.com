---
layout: post
title: "hadoop2 use ShortCircuit local reading"
date: 2014-07-29 20:11:58 +0800
comments: true
categories: [hadoop]
---

hadoop一直以来认为是本地读写文件的，但是其实也是通过TCP端口去获取数据，只是都在同一台机器。在hivetuning调优hive的文档中看到了ShortCircuit的HDFS配置属性，查看了ShortCircuit的来由，真正的实现了本地读取文件。蒙查查表示看的不是很明白，最终大致就是通过linux的**文件描述符**来实现功能同时保证文件的权限。

由于仅在自己的机器上面配置来查询hbase的数据，性能方面提升感觉不是很明显。等以后整到正式环境再对比对比。

配置如下。

1 修改hdfs-site.xml

```
<property>
        <name>dfs.client.read.shortcircuit</name>
        <value>true</value>
</property>

<property>
        <name>dfs.domain.socket.path</name>
        <value>/home/hadoop/data/sockets/dn_socket</value>
</property>
```

注意：socket路径的权限控制的比较严格。dn_socket**所有的父路径**要么仅有当前启动用户的读权限，要么仅root可读。

![](http://file.bmob.cn/M00/05/52/wKhkA1PXfbKANLOrAADWJQ5taVs391.png)

2 修改hbase的配置，并添加HADOOP_HOME（hbase查找hadoop-native）

![](http://file.bmob.cn/M00/05/52/wKhkA1PXhRKAZDs6AAChrEauBoU738.png)

hbase的脚本找到hadoop命令后，会把hadoop的java.library.path的路径加入到hbase的启动脚本中。

```
[hadoop@master1 ~]$ tail -15 hbase-0.98.3-hadoop2/conf/hbase-site.xml 
    <name>hbase.tmp.dir</name>
    <value>/home/hadoop/data/hbase</value>
  </property>

<property>
        <name>dfs.client.read.shortcircuit</name>
        <value>true</value>
</property>

<property>
        <name>dfs.domain.socket.path</name>
        <value>/home/hadoop/data/sockets/dn_socket</value>
</property>

</configuration>

[hadoop@master1 ~]$ cat hbase-0.98.3-hadoop2/conf/hbase-env.sh
...
export HADOOP_HOME=/home/hadoop/hadoop-2.2.0
...

```

3 同步到其他节点，然后重启hdfs,hbase

## 参考

* [hive-tuning](http://vdisk.weibo.com/s/z_44nz36hNM3Z)
* [How Improved Short-Circuit Local Reads Bring Better Performance and Security to Hadoop](http://blog.cloudera.com/blog/2013/08/how-improved-short-circuit-local-reads-bring-better-performance-and-security-to-hadoop/)
* [HDFS--Apache HBase Performance Tuning](http://hbase.apache.org/book/perf.hdfs.html)
* [HDFS Short-Circuit Local Reads](http://archive.cloudera.com/cdh4/cdh/4/hadoop/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html)
