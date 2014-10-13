---
layout: post
title: "[读码] hadoop2 balancer磁盘空间平衡（中）"
date: 2014-09-05 14:57:25 +0800
comments: true
categories: [hadoop]
---

## code

执行`hadoop-2.2.0/bin/hadoop balancer -h`查看可以设置的参数（和sbin/start-balancer.sh一样）。

```
Usage: java Balancer
	[-policy <policy>]	the balancing policy: datanode or blockpool
	[-threshold <threshold>]	Percentage of disk capacity
```

main方法入口，可以接受threshold（大于等于1小于等于100， 默认值10）和policy（可取datanode[dfsused]/blockpool[
blockpoolused]， 默认值datanode），具体的含义可以查看（上）篇中的javadoc的描述。

### 获取初始化参数

然后通过ToolRunner解析参数，并运行Cli工具类来执行HDFS的平衡。

1 设置检查

`WIN_WIDTH`(默认1.5h) 已移动的数据会记录movedBlocks（list）变量中，在移动成功的数据`CUR_WIN`的值经过该时间后会被移动到`OLD_WIN`---现在感觉作用不大，为了减少map的大小？

`checkReplicationPolicyCompatibility()`检查配置`dfs.block.replicator.classname`是否为BlockPlacementPolicyDefault子类，即是否满足3份备份的策略（1st本地，2nd另一个rack，3rd和第二份拷贝不同rack的节点）？

2 获取nameserviceuris

通过`DFSUtil#getNsServiceRpcUris()`来获取namenodes，调用`getNameServiceUris()`来得到一个URI的结果集：

```
+ nsId <- dfs.nameservices
  ? ha  <- dfs.namenode.rpc-address + [dfs.nameservices] + [dfs.ha.namenodes]
    Y+ => hdfs://nsId
    N+ => hdfs://[dfs.namenode.servicerpc-address.[nsId]] 或 hdfs://[dfs.namenode.rpc-address.[nsId]] 第二个满足条件的加入到nonPreferredUris
+ hdfs://[dfs.namenode.servicerpc-address] 或 hdfs://[dfs.namenode.rpc-address]  第二个满足条件的加入到nonPreferredUris
? [fs.defaultFs] 以hfds开头，且不在nonPreferredUris集合中是加入结果集
```

HA情况下的地址相关配置项可以查看[官网的文档](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html)

```
dfs.nameservices
dfs.ha.namenodes.[nameservice ID]
dfs.namenode.rpc-address.[nameservice ID].[name node ID] 
```

3 解析threshold和policy参数

默认值: **BalancingPolicy.Node.INSTANCE, 10.0**。运行打印的日志如下，INFO日志中包括了初始化的参数信息。

```
2014-09-05 10:55:12,183 INFO Balancer: Using a threshold of 1.0
2014-09-05 10:55:12,186 INFO Balancer: namenodes = [hdfs://umcc97-44:9000]
2014-09-05 10:55:12,186 INFO Balancer: p         = Balancer.Parameters[BalancingPolicy.Node, threshold=1.0]
2014-09-05 10:55:13,744 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
2014-09-05 10:55:18,154 INFO net.NetworkTopology: Adding a new node: /default-rack/10.18.97.142:50010
2014-09-05 10:55:18,249 INFO net.NetworkTopology: Adding a new node: /default-rack/10.18.97.144:50010
2014-09-05 10:55:18,311 INFO net.NetworkTopology: Adding a new node: /default-rack/10.18.97.143:50010
2014-09-05 10:55:18,319 INFO Balancer: 2 over-utilized: [Source[10.18.97.144:50010, utilization=8.288283273062705], Source[10.18.97.143:50010, utilization=8.302032354001554]]
2014-09-05 10:55:18,320 INFO Balancer: 1 underutilized: [BalancerDatanode[10.18.97.142:50010, utilization=4.716543864576553]]
2014-09-05 10:55:33,918 INFO Balancer: Need to move 3.86 GB to make the cluster balanced.
2014-09-05 11:21:16,875 INFO Balancer: Decided to move 2.43 GB bytes from 10.18.97.144:50010 to 10.18.97.142:50010
2014-09-05 11:24:16,712 INFO Balancer: Decided to move 1.84 GB bytes from 10.18.97.143:50010 to 10.18.97.142:50010
2014-09-05 11:25:55,726 INFO Balancer: Will move 4.27 GB in this iteration
```

### 执行Balancer

4 调用Balancer#run执行

```
 # 调试命令
 export HADOOP_OPTS=" -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8087 "
 sbin/start-balancer.sh 
``` 

Balancer的静态方法run，循环处理所有namenodes。在实例化namenode的NameNodeConnector对象时，会把当前运行balancer程序的hostname写入到HDFS的`/system/balancer.id`文件中，可以用来控制同时只有一个balancer运行。

![](http://file.bmob.cn/M00/0C/96/wKhkA1QJJNqAXxeaAAAho0g2bEU520.png)

在循环处理的时刻使用`Collections.shuffle(connectors)`打乱了namenodes的顺序。

Balancer的静态方法run中是一个双层循环，实例化Balancer并调用实例方法run来处理每个namenode的平衡。运行后要么**出错**要么就是平衡**顺利完成**才算结束。平衡的返回状态值及其含义可以查看javadoc（上）篇。

```
  static int run(Collection<URI> namenodes, final Parameters p,
      Configuration conf) throws IOException, InterruptedException {
	  ...
      for (URI uri : namenodes) {
        connectors.add(new NameNodeConnector(uri, conf));
      }
    
      boolean done = false;
      for(int iteration = 0; !done; iteration++) {
        done = true;
        Collections.shuffle(connectors);
        for(NameNodeConnector nnc : connectors) {
          final Balancer b = new Balancer(nnc, p, conf);
          final ReturnStatus r = b.run(iteration, formatter, conf);
          // clean all lists
          b.resetData(conf);
          if (r == ReturnStatus.IN_PROGRESS) {
            done = false;
          } else if (r != ReturnStatus.SUCCESS) {
            //must be an error statue, return.
            return r.code;
          }
        }

        if (!done) {
          Thread.sleep(sleeptime);
        }
      }
	  ...
  }
```

5 **针对每个namenode的平衡处理**

针对每个namenode的每次迭代，又可以分出初始化节点、选择移动节点、移动数据三个部分。

```
  private ReturnStatus run(int iteration, Formatter formatter, Configuration conf) {
      ...
      final long bytesLeftToMove = initNodes(nnc.client.getDatanodeReport(DatanodeReportType.LIVE));
      if (bytesLeftToMove == 0) {
        System.out.println("The cluster is balanced. Exiting...");
        return ReturnStatus.SUCCESS;
      }

      final long bytesToMove = chooseNodes();
      if (bytesToMove == 0) {
        System.out.println("No block can be moved. Exiting...");
        return ReturnStatus.NO_MOVE_BLOCK;
      }

      if (!this.nnc.shouldContinue(dispatchBlockMoves())) {
        return ReturnStatus.NO_MOVE_PROGRESS;
      }

      return ReturnStatus.IN_PROGRESS;
      ...
  }
```  

获取集群Live Datanode节点的信息，和通过50070查看的信息差不多，然后调用initNode()方法。

![](http://file.bmob.cn/M00/0C/8F/wKhkA1QJFgaAAsSNAAD4HDo1RfA678.png)

5.1 初始化节点

`initNodes()`中获取每个Datanode的capacity和dfsUsed数据，计算整个集群dfs的平均使用率avgUtilization。
然后根据每个节点的使用率与集群使用率，以及阀值进行比较划分为4种情况：
`overUtilizedDatanodes`，`aboveAvgUtilizedDatanodes`，`belowAvgUtilizedDatanodes`，`underUtilizedDatanodes`。

![](http://file.bmob.cn/M00/0C/95/wKhkA1QJH2uAa8UEAABq7RCSLQ0452.png)

同时取超出**平均+阀值**和**低于平均-阀值**的字节数最大值，即集群达到平衡需要移动的字节数。

为了测试，如果集群已经平衡，可以搞点数据让集群不平衡，方便查看调试。

```
bin/hadoop fs -D dfs.replication=1 -put XXXXX /abc

sbin/start-balancer.sh -threshold 1
```

5.2 选择节点

初始化节点后，计算出了需要移动的数据量。接下来就是选择移动数据的节点`chooseNodes`，以及接收对应数据的节点。

```
  private long chooseNodes() {
    // First, match nodes on the same node group if cluster is node group aware
    if (cluster.isNodeGroupAware()) {
      chooseNodes(SAME_NODE_GROUP);
    }
    
    chooseNodes(SAME_RACK);
    chooseNodes(ANY_OTHER);

    long bytesToMove = 0L;
    for (Source src : sources) {
      bytesToMove += src.scheduledSize;
    }
    return bytesToMove;
  }
  private void chooseNodes(final Matcher matcher) {
    chooseDatanodes(overUtilizedDatanodes, underUtilizedDatanodes, matcher);
    chooseDatanodes(overUtilizedDatanodes, belowAvgUtilizedDatanodes, matcher);
    chooseDatanodes(underUtilizedDatanodes, aboveAvgUtilizedDatanodes, matcher);
  }

  private <D extends BalancerDatanode, C extends BalancerDatanode> void 
      chooseDatanodes(Collection<D> datanodes, Collection<C> candidates,
          Matcher matcher) {
    for (Iterator<D> i = datanodes.iterator(); i.hasNext();) {
      final D datanode = i.next();
      for(; chooseForOneDatanode(datanode, candidates, matcher); );
      if (!datanode.hasSpaceForScheduling()) {
        i.remove(); // “超出”部分全部有去处了
      }
    }
  }

  private <C extends BalancerDatanode> boolean chooseForOneDatanode(
      BalancerDatanode dn, Collection<C> candidates, Matcher matcher) {
    final Iterator<C> i = candidates.iterator();
    final C chosen = chooseCandidate(dn, i, matcher);

    if (chosen == null) {
      return false;
    }
    if (dn instanceof Source) {
      matchSourceWithTargetToMove((Source)dn, chosen);
    } else {
      matchSourceWithTargetToMove((Source)chosen, dn);
    }
    if (!chosen.hasSpaceForScheduling()) {
      i.remove(); // 可用的空间已经全部分配出去了
    }
    return true;
  }

  private <D extends BalancerDatanode, C extends BalancerDatanode>
      C chooseCandidate(D dn, Iterator<C> candidates, Matcher matcher) {
    if (dn.hasSpaceForScheduling()) {
      for(; candidates.hasNext(); ) {
        final C c = candidates.next();
        if (!c.hasSpaceForScheduling()) {
          candidates.remove();
        } else if (matcher.match(cluster, dn.getDatanode(), c.getDatanode())) {
          return c;
        }
      }
    }
    return null;
  }  
```

选择到**接收节点**后，接下来计算可以移动的数据量（取双方的available的最大值），然后把**接收节点**和**数据量**的信息NodeTask存储到Source的NodeTasks对象中。

```
  private void matchSourceWithTargetToMove(
      Source source, BalancerDatanode target) {
    long size = Math.min(source.availableSizeToMove(), target.availableSizeToMove());
    NodeTask nodeTask = new NodeTask(target, size);
    source.addNodeTask(nodeTask);
    target.incScheduledSize(nodeTask.getSize());
    sources.add(source);
    targets.add(target);
  }
```

5.3 移动数据

（待）