---
layout: post
title: "hadoop的datanode数据节点软/硬件配置应该一致"
date: 2014-08-02 22:21:12 +0800
comments: true
categories: [hadoop]
---

最好的就是集群的所有的datanode的节点的**硬件配置一样**！当然系统时间也的一致，hosts等等这些。机器配置一样时可以使用脚本进行批量处理，给维护带来很大的便利性。

今天收到运维的信息，说集群的一台机器硬盘爆了！上到环境查看`df -h`发现硬盘配置和其他datanode的不同！但是hadoop hdfs-site.xml的`dfs.datanode.data.dir`却是一样的！

经验： dir的配置应该是一个系统设备对应一个路径，而不是一个系统目录对应dir的一个路径！


## 问题现象以及根源

问题机器A的磁盘情况：

```
[hadoop@hadoop-slaver8 ~]$ df -h
文件系统              容量  已用  可用 已用%% 挂载点
/dev/sda3             2.7T  2.5T   53G  98% /
tmpfs                  32G  260K   32G   1% /dev/shm
/dev/sda1              97M   32M   61M  35% /boot

[hadoop@hadoop-slaver8 /]$ ll
总用量 170
dr-xr-xr-x.   2 root   root    4096 2月  12 19:39 bin
dr-xr-xr-x.   5 root   root    1024 2月  13 02:40 boot
drwxr-xr-x.   2 root   root    4096 2月  23 2012 cgroup
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data1
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data10
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data11
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data12
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data13
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data14
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data15
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data2
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data3
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data4
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data5
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data6
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data7
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data8
drwxr-xr-x.   3 hadoop hadoop  4096 6月  30 10:36 data9
```

再看集群其他机器：

```
[hadoop@hadoop-slaver1 ~]$ df -h
文件系统              容量  已用  可用 已用%% 挂载点
/dev/sda3             2.7T   32G  2.5T   2% /
tmpfs                  32G   88K   32G   1% /dev/shm
/dev/sda1              97M   32M   61M  35% /boot
/dev/sdb1             1.8T  495G  1.3T  29% /data1
/dev/sdb2             1.8T  485G  1.3T  28% /data2
/dev/sdb3             1.8T  492G  1.3T  29% /data3
/dev/sdb4             1.8T  488G  1.3T  28% /data4
/dev/sdb5             1.8T  486G  1.3T  28% /data5
/dev/sdb6             1.8T  480G  1.3T  28% /data6
/dev/sdb7             1.8T  479G  1.3T  28% /data7
/dev/sdb8             1.8T  474G  1.3T  28% /data8
/dev/sdb9             1.8T  480G  1.3T  28% /data9
/dev/sdb10            1.8T  478G  1.3T  28% /data10
/dev/sdb11            1.8T  475G  1.3T  28% /data11
/dev/sdb12            1.8T  489G  1.3T  29% /data12
/dev/sdb13            1.8T  475G  1.3T  28% /data13
/dev/sdb14            1.8T  476G  1.3T  28% /data14
/dev/sdb15            1.8T  469G  1.3T  27% /data15
```

出问题机器没有挂存储，仅仅是建立了对应的目录结构，并不是把目录挂载到单独的存储设备上。

同时查看50070的前面的信息，hadoop把每个逗号分隔后的路径默认都做一个磁盘设备来计算！

```
Node 	          Address             ..Admin State CC    Used  NU    RU(%) R(%) 	  Blocks Block  Pool Used Block Pool Used (%)
hadoop-slaver1	192.168.32.21:50010	2	In Service	26.86	7.05	1.37	18.44	26.25		68.66	264844 	7.05	26.25	
hadoop-slaver8	192.168.32.28:50010	1	In Service	37.94	2.46	34.71	0.77	6.48		2.03	29637 	2.46	6.48	
```

配置容量是所有配置的路径所在盘容量的**累加**。总的剩余空间（余量）也是各个dir配置路径的剩余空间**累加**的！这样很容易出现问题！
最好的就是集群的所有的datanode的节点的**硬件配置一样**！当然系统时间也的一致，hosts等等这些。

## 问题处理

首先得把问题解决啊：

* 把`dfs.datanode.data.dir`路径个数调整为磁盘个数！
* 修改该datanode的hdfs-site的配置，添加`dfs.datanode.du.reserved`，留给系统的空间设置为400多G。
* 冗余份数也没有必要3份，浪费空间。如果两台机器同时出现问题，还是同一份数据，那只能说是天意！你可以去趟澳门赌一圈了！

```
<property>
<name>dfs.datanode.data.dir</name>
<value>/data1/hadoop/data</value>
</property>
<property>
<name>dfs.datanode.du.reserved</name>
<value>437438953472</value>
</property>
<property>
<name>dfs.replication</name>
<value>2</value>
</property>
```

设置了reserved保留空间后，再看LIVE页面slaver8的容量变少了且正好等于(盘的容量2.7T-430G~=2.26T 计算容量的hdfs源码在`FsVolumeImpl.getCapacity()`)。

```
hadoop-slaver8	192.168.32.28:50010	1	In Service	2.26	2.23	0.00	0.03	98.66
```

datanode和blockpool的平衡处理，可以参考[Live Datanodes](http://hadoop-master1:50070/dfsnodelist.jsp?whatNodes=LIVE)的容量和进行！

```
[hadoop@hadoop-master1 ~]$ hdfs balancer -help
Usage: java Balancer
        [-policy <policy>]      the balancing policy: datanode or blockpool
        [-threshold <threshold>]        Percentage of disk capacity

[hadoop@hadoop-slaver8 ~]$ hadoop-2.2.0/bin/hdfs getconf -confkey dfs.datanode.du.reserved
137438953472
```

删除一些没用的备份数据。配置好以后，重启当前slaver8节点，并进行数据平衡（如果觉得麻烦，直接丢掉原来的一个目录下的数据也行，可能更快！均衡器运行的太慢！！）

```
[hadoop@hadoop-slaver8 ~]$  ~/hadoop-2.2.0/sbin/hadoop-daemon.sh stop datanode

[hadoop@hadoop-slaver8 ~]$  for i in 6 7 8 9 10 11 12 13 14 15; do  cd /data$i/hadoop/data/current/BP-1414312971-192.168.32.11-1392479369615/current/finalized;  find . -type f -exec mv {} /data1/hadoop/data/current/BP-1414312971-192.168.32.11-1392479369615/current/finalized/{} \;; done

[hadoop@hadoop-slaver8 ~]$  ~/hadoop-2.2.0/sbin/hadoop-daemon.sh start datanode


[hadoop@hadoop-master1 ~]$ hdfs dfsadmin -setBalancerBandwidth 10485760
[hadoop@hadoop-master1 ~]$ hdfs balancer -threshold 60

```

查看datanode的日志，由于移动数据，有些blk的id一样，会清理一些数据。对于均衡器程序的阀值越小集群越平衡！默认是10（%），会移动很多的数据（准备看下均衡器的源码，了解各个参数以及运行的逻辑）！

## 参考

* [hadoop的datanode多磁盘空间处理](http://blog.csdn.net/lingzihan1215/article/details/8700532)
