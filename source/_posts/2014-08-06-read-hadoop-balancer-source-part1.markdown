---
layout: post
title: "[读码] hadoop2 balancer磁盘空间平衡（上）"
date: 2014-08-06 22:14:29 +0800
comments: true
categories: [hadoop]
---

## javadoc

在一些节点满了或者加入了新的节点情况下，使用balancer工具可以平衡HDFS集群磁盘空间使用率。该功能作为一个单独的程序，能同时与集群的其他文件操作一起进行。

threshold（阀值）参数是个介于1%~100%的值，默认情况下是10%。指定了集群达到平衡的指标值。当节点的利用率（所在节点的磁盘使用率，只HDFS可利用的部分）与集群利用率（集群HDFS的使用率）之间的差不大于阀值threshold就表示集群已经处于平衡状态。所以，阀值threshold越小，集群各节点数据分布越平衡（集群越平衡），当然这也会耗费更多的时间来达到小的平衡阀值。同时，当数据同时又在进行读写操作时，可能平衡并不能达到非常小的阀值。

![](http://file.bmob.cn/M00/0C/95/wKhkA1QJH2uAa8UEAABq7RCSLQ0452.png)

这个工具依次地把磁盘使用率高的机器的块移动到使用率低的数据节点上。每次迭代移动/接受的数据小于10G或者节点容量的阀值百分比（In each iteration a datanode moves or receives no more than the lesser of 10G bytes or the threshold fraction of its capacity. ）。每次迭代不会大于20分钟。每次迭代完成后，balancer把数据节点信息更新到namenode，重新计算利用率后，再进行下一次迭代直到集群利用率阀值。

配置`dfs.balance.bandwidthPerSec`控制balancer操作传输的带宽，默认配置是1048576（1M/s）这个属性决定了一个块从一个数据节点移动到另一个节点的最大速率。默认是1M/s。bandwidth越高集群达到平衡越快，但是程序之间的竞争会更激烈。如果通过配置文件来修改这个属性，需要在下次启动HDFS才能生效。可以通过`hdfs dfsadmin -setBalancerBandwidth 10485760`来动态的设置。

每次迭代会输出开始时间，迭代的次数，上一次迭代移动的数据量，集群达到平衡还需要移动的数据量，该次迭代将移动的数据量。一般情况下，“Bytes Already Moved”将会增加同时“Bytes Left To Move”将会减少（但是如果此时有大数据量写入，那么Bytes Left To Move可能不减反增）。

```
Time Stamp               Iteration#  Bytes Already Moved  Bytes Left To Move  Bytes Being Moved
```

多个balancer程序不能同时运行。

balancer程序会自动退出当存在以下情况：

* 集群已经平衡
* 没有块将会被移动
* 连续5次的处理没有块移动
* 连接namenode时出现IOException
* 另一个balancer程序在跑

根据上面的5中情况，balancer程序退出，同时会打印如下的信息：

 * The cluster is balanced. Exiting
 * No block can be moved. Exiting...
 * No block has been moved for 5 iterations. Exiting...
 * Received an IO exception: failure reason. Exiting...
 * Another balancer is running. Exiting...

当balancer运行时，管理员可以随时运行stop-balancer.sh来中断balancer程序。

