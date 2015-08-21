---
layout: post
title: "tachyon剖析"
date: 2015-04-18 23:13:01 +0800
comments: true
categories: [tachyon]
---

要了解一个框架，一般都是从框架提供/开放的接口入手。先从最直接的方式下手，可以通过`tachyon tfs`和浏览器19999端口获取集群以及文件的相关信息。

* 要了解tachyon首先就是其文件系统，可以从两个功能开始：命令行tachyon.command.TFsShell和web-servlet。
* 然后会深入tachyon.client包，了解**TachyonFS**和TachyonFile处理io的方式。以及tachyon.hadoop的包。
* io处理：
	* 写：BlockOutStream（#getLocalBlockTemporaryPath； MappedByteBuffer）、FileOutStream
	* 读：RemoteBlockInStream、LocalBlockInStream
* 了解thrift：MasterClient、MasterServiceHandler、WorkerClient、WorkerServiceHandler、ClientBlockInfo、ClientFileInfo。
* 看tachyon.example，巩固

注：MappedByteBuffer在windows存在资源占用的bug！参见<http://www.th7.cn/Program/java/2012/01/31/57401.shtml>，

把整个io流理清之后，然后需要了解tachyon是怎么维护这些信息的：

* 配置：WorkerConf、MasterConf、UserConf
* 了解thrift：MasterClient、MasterServiceHandler、ClientWorkerInfo、MasterInfo
* TachyonMaster和TachyonWorker的启动
* Checkpoint、Image、Journal
* 内存淘汰策略
* DataServer在哪里用到（nio/netty）：TachyonFile#readRemoteByteBuffer、RemoteBlockInStream#read(byte[], int, int)
* HA
* Dependency（不知道怎么用）

远程调试Worker以及tfs：

```
[hadoop@hadoop-master2 tachyon-0.6.1]$ cat conf/tachyon-env.sh 
export TACHYON_WORKER_JAVA_OPTS="$TACHYON_JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8070"

[hadoop@hadoop-master2 tachyon-0.6.1]$ export TACHYON_JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8070"
[hadoop@hadoop-master2 tachyon-0.6.1]$ bin/tachyon tfs lsr /
```

## IO/client

* TachyonFS是client与Master/Worker的纽带，请求**文件系统和文件**的元数据CRUD操作。其中的WorkerClient仅用于写（保存）文件。
* TachyonFile是文件的抽象处理集合，可以获取文件的基本属性（元数据），同时提供了IO的接口用于文件内容的读写。
* InStream读、获取文件内容
	* EmptyBlockInStream(文件包括的块为0）
	* BlockInStream(文件包括的块为1）
		* LocalBlockInStream 仅当是localworker且该块在本机时，通过MappedByteBuffer获取数据（数据在ramdisk也就是内存盘上哦）。
		* RemoteBlockInStream （通过nio从远程的worker#DataServer机器获取数据#retrieveByteBufferFromRemoteMachine，如果readtype设置为cache同时把数据缓冲到本地worker）
	* FileInStream(文件包括的块为1+，可以理解为BlocksInStream。通过mCurrentPosition / mBlockCapacity来获取当前的blockindex最终还是调用BlockInStream）
* FileOutStream写，写数据入口就是只有FileOutStream
	* BlockOutStream（WriteType设置了需要缓冲，会写到本地localworker。**由于需要进行分块，会复杂些#appendCurrentBuffer**）
	* UnderFileSystem（如果WriteType设置了Through，则把数据写一份到underfs文件系统）

## Master

TachyonMaster是master的启动类，所有的服务都是在这个类里面初始化启动的。

* HA：LeaderSelectorClient
* EditLog：EditLogProcessor、Journal。
	* 如果是HA模式，leader调用setup方法把EditLogProcessor停掉。也就是说在HA模式下，standby才会运行EditLogProcessor实时处理editlog。
	* leader和非HA master则仅在启动时通过调用MasterInfo#init处理editlog一次。
* Thrift: TServer、MasterServiceHandler；与MasterClient对应的服务端。
* Web: UIWebServer，使用jetty的内嵌服务器。
* MasterInfo

## Worker

## Thrift
	
## HA

当配置`tachyon.usezookeeper`设置为true时，启动master时会初始化LeaderSelectorClient对象。使用curator连接到zookeeper服务器进行leader的选举。

**LeaderSelectorClient**实现了LeaderSelectorListener接口，创建LeaderSelector并传入当前实例作为监听实例，当选举完成后，被选leader触发takeLeadership事件。

> public void takeLeadership(CuratorFramework client) throws Exception
> Called when your instance has been granted leadership. This method should not return until you wish to release leadership

takeLeadership方法中把`mIsLeader`设置为true（master自己判断）、创建`mLeaderFolder + mName`路径（客户端获取master leader）；然后隔5s的死循环（运行在LeaderSelector单独的线程池）。

## Checkpoint

## Journal

	
- - - -

## 问题

* 程序没有返回内容，没有响应

tfs 默认是CACHE_THROUGH，会缓冲同时写ufs。如果改成must则只写cache，然后清理内存，再获取数据，一直没有内容返回，不知道为什么？

```
[eshore@bigdata1 tachyon-0.6.1]$ export TACHYON_JAVA_OPTS="-Dtachyon.user.file.writetype.default=MUST_CACHE "
[eshore@bigdata1 tachyon-0.6.1]$ bin/tachyon tfs copyFromLocal LICENSE /LICENSE2
Copied LICENSE to /LICENSE2
[eshore@bigdata1 tachyon-0.6.1]$ bin/tachyon tfs free /LICENSE2
/LICENSE2 was successfully freed from memory.
[eshore@bigdata1 tachyon-0.6.1]$ bin/tachyon tfs cat /LICENSE2
```

