---
layout: post
title: "[读码] hadoop2 balancer磁盘空间平衡（下）"
date: 2014-09-05 16:31:15 +0800
comments: true
categories: [hadoop]
---

前面讲到了节点的初始化，根据节点使用率与集群dfs使用率比较分为
`overUtilizedDatanodes`，`aboveAvgUtilizedDatanodes`，`belowAvgUtilizedDatanodes`，`underUtilizedDatanodes`，同时进行了节点数据量从Source到Target的配对。

接下来就是最后的数据移动部分了。

5.3 移动数据

```
  private ReturnStatus run(int iteration, Formatter formatter,
      Configuration conf) {
      ...
      if (!this.nnc.shouldContinue(dispatchBlockMoves())) {
        return ReturnStatus.NO_MOVE_PROGRESS;
      }
      ...
  }    
```

针对一个namenode如果连续5次没有移动数据，就会退出平衡操作，是在`NameNodeConnector#shouldContinue(long)`中处理的。

由于这里需要进行大量计算，以及耗时的文件传输等操作，这里使用了executorservice，分别为moverExecutor和dispatcherExecutor，有两个配置`dfs.balancer.moverThreads`（1000）和`dfs.balancer.dispatcherThreads`（200）来设置线程池的大小。

```
  Balancer(NameNodeConnector theblockpool, Parameters p, Configuration conf) {
		...
    this.moverExecutor = Executors.newFixedThreadPool(
            conf.getInt(DFSConfigKeys.DFS_BALANCER_MOVERTHREADS_KEY,
                        DFSConfigKeys.DFS_BALANCER_MOVERTHREADS_DEFAULT));
    this.dispatcherExecutor = Executors.newFixedThreadPool(
            conf.getInt(DFSConfigKeys.DFS_BALANCER_DISPATCHERTHREADS_KEY,
                        DFSConfigKeys.DFS_BALANCER_DISPATCHERTHREADS_DEFAULT));
  }
```

其中`dispatchBlockMoves()`包装了数据移动的操作，把source的块移动到target节点中。

```
  private long dispatchBlockMoves() throws InterruptedException {
    long bytesLastMoved = bytesMoved.get();
    Future<?>[] futures = new Future<?>[sources.size()];
    int i=0;
    for (Source source : sources) {
    	 // / 新线程来执行块的分发
      futures[i++] = dispatcherExecutor.submit(source.new BlockMoveDispatcher());
    }
    
    // wait for all dispatcher threads to finish
    // / 等待分发操作完成
    for (Future<?> future : futures) { 
        future.get(); 
    }
    
    // wait for all block moving to be done
    // / 等待块的数据移动完成，相当于等待moverExecutor的Future完成
    waitForMoveCompletion(); 
    
    return bytesMoved.get()-bytesLastMoved;
  }
  private void waitForMoveCompletion() {
    boolean shouldWait;
    do {
      shouldWait = false;
      for (BalancerDatanode target : targets) {
      	// / 块从source移动到target完成后,会从Pending的列表中移除 @see PendingBlockMove#dispatch()
        if (!target.isPendingQEmpty()) { 
          shouldWait = true;
        }
      }
      if (shouldWait) {
        try {
          Thread.sleep(blockMoveWaitTime);
        } catch (InterruptedException ignored) {
        }
      }
    } while (shouldWait);
  }
```

上面是分发功能主程序执行的代码，调用分发线程和等待执行结果的代码。主要业务逻辑在线程中调用执行。

分发线程dispatcher先获取Source上指定大小的block块，对应到`getBlockList()`方法。除了用于**块同步**的globalBlockList变量、以及记录当前Source获取的srcBlockList、最重要的当属用于判断获取的块是否符合条件的方法`isGoodBlockCandidate(block)`。在移动块的选择也会用到该方法，单独拿出来在后面讲。

然后选择Source下哪些块将移动到Targets目标节点。在`chooseNodes`步骤中把移动和接收**数据**的流向确定了，相关信息存储在Source的nodeTasks列表对象中。这里`PendingBlockMove.chooseBlockAndProxy()`把Sources需要移动的**块**确定下来，把从Source获取到的srcBlockList分配给Target。然后交给moverExecutor去执行。

其中通过`isGoodBlockCandidate`和`chooseProxySource`（选择从那个目标获取block的真实数据，不一定是Source节点哦！）方法筛选合适的符合条件的块，并加入到movedBlocks对象。

![](http://file.bmob.cn/M00/0C/FA/wKhkA1QLCqqASDGHAAMJbC1ZgZQ339.png)

调用的dispatchBlocks方法第一次循环是不会有数据移动的，此时Source对象中srcBlockList可移动块为空，从Source中获取块后再进行块的移动操作`chooseNextBlockToMove()`。

先讲下Source类属性blocksToReceive，初始值为2*scheduledSize，有三个地方：dispatchBlocks初始化大小，getBlockList从Source节点获取block的量同时减去获取到的block的字节数，还有就是shouldFetchMoreBlocks用于判断是否还有数据需要获取或者移动dispatchBlocks。这个属性其实也就是**设置一个阀**，不管block是否为最终移动的block，获取到块的信息后就会从blocksToReceive减去相应的字节数。

![](http://file.bmob.cn/M00/0C/D7/wKhkA1QJjnGAT2T-AACHmpdgZc0077.png)

前面获取Source block和分配到Target block都使用了isGoodBlockCandidate方法，这里涉及到怎么去评估**块**获取和分配是否合理的问题。需同时满足下面三个条件：

* 当前选中的移动的块，不在已移动块的名单中`movedBlocks.contains`
* 移动的块在目的机器上没有备份
* 移动的块不减少含有该数据的机架数量
	* 多机架的情况下`cluster.isNodeGroupAware()`，移动的块在目的机器的机架上没有备份
	* YES source和target在同一个机架上。
	* YES source和target不在同一机架上，且该块没有一个备份在target的机架上
	* YES source和target不在同一机架上，且该块有另一个备份和source在同一机架上

## 疑问
	
一个Datanode只能同时移动/接收5个Block（即MAX_NUM_CONCURRENT_MOVES值），结合`chooseProxySource`的代码的addTo调用，看的很是辛苦！如block-A所有块都在A机架上，在选择proxySource时，会把该块的**两个**datanode都加上一个pendingBlock，显然这不大合理！！

如果备用的proxySource节点恰好还是target的话，waitForMoveCompletion方法永远不能结束！！应该把没有找到同机架的源情况移到for循环外面进行处理。

```
    private boolean chooseProxySource() {
      final DatanodeInfo targetDN = target.getDatanode();
      boolean find = false;
      for (BalancerDatanode loc : block.getLocations()) {
        // check if there is replica which is on the same rack with the target
        if (cluster.isOnSameRack(loc.getDatanode(), targetDN) && addTo(loc)) {
          find = true;
          // if cluster is not nodegroup aware or the proxy is on the same 
          // nodegroup with target, then we already find the nearest proxy
          if (!cluster.isNodeGroupAware() 
              || cluster.isOnSameNodeGroup(loc.getDatanode(), targetDN)) {
            return true;
          }
        }
        
        if (!find) {
		  // 这里的non-busy指的是，pendingBlock小于5份节点
          // find out a non-busy replica out of rack of target
          find = addTo(loc);
        }
      }
      
      return find;
    }
```

![](http://file.bmob.cn/M00/0D/06/wKhkA1QLuziAKEZdAAA8zGjPMGQ901.png)

不过无需庸人自扰，一般都在一个rack上，这种问题就不存在了！同时这个也不是能一步到位，加了很多限制（一次迭代一个datanode最多处理10G，获取一次srcBlockList仅2G还限制就一次迭代就5个block），会执行很多次。

## 总结

总体的代码大致就是这样子了。根据集群使用率和阀值，计算需要进行数据接收和移动的节点（初始化），然后进行配对（选择），再进行块的选取和接收节点进行配对（分发），最后就是数据的移动（理解为socket数据传递就好了，调用了HDFS的协议代码。表示看不明），并等待该轮操作结束。

## 举例

除了指定threshold为5，其他是默认参数。由于仅单namenode和单rack，所以直接分析第五部分的namenode平衡处理。

根据所给的数据，（initNodes）第一步计算使用率，得出需要移动的数据量，把datanodes对号入座到over/above/below/under四个分类中。

![](http://file.bmob.cn/M00/0D/08/wKhkA1QLwxiAOEV3AAAu5v9zggc374.png)

（chooseNodes）第二步进行Source到Target节点的计划移动数据量计算。

在初始化BalancerDatanode的时刻，就计算出了节点的maxSize2Move。从给出的数据，只有一个节点超过阀值，另外两个是都在阀值内，一个高于平均值一个低于平均值。

这里就是把A1超出部分的数据（小于10G）移到A2，计算Source和Target的scheduledSize的大小。

```
chooseDatanodes(overUtilizedDatanodes, belowAvgUtilizedDatanodes, matcher);
chooseForOneDatanode(datanode, candidates, matcher)
chooseCandidate(dn, i, matcher)
// 把所有A1超出部分全部移到A2，并NodeTask(A2, 8428571.429)存储到Source：A1的nodeTaskList对象中
matchSourceWithTargetToMove((Source)dn, chosen);
```

（dispatchBlockMoves）第三步就是分发进行块的转移。

先设置blocksToReceive（2*scheduledSize=16857142.86）

```
chooseNextBlockToMove
chooseBlockAndProxy
markMovedIfGoodBlock
isGoodBlockCandidate
chooseProxySource

scheduleBlockMove

getBlockList
```

从Source获取块时，可能在A2上已经有了，会通过isGoodBlockCandidate来进行过滤。然后就是把它交给moverExecutor执行数据块的移动，完成后修改处理的数据量byteMoved，把移动的块从target和proxySource的pendingBlockList中删除。

重复进行以上步骤，直到全部所有节点的使用率都在阀值内，顺利结束本次平衡处理。
