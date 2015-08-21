---
layout: post
title: "查找逐步定位Java程序OOM的异常实践"
date: 2014-08-25 21:12:13 +0800
comments: true
categories: [java]
---

类C语言，继C++之后的最辉煌耀眼的明星都属Java，其中最突出的又数内存管理。JVM对运行在其上的程序进行内存自动化分配和管理，减少开发人员的工作量之外便于统一的维护和管理。JDK提供了各种各样的工具来让开发实施人员了解运行的运行状态。

* jps -l -v -m
* jstat -gcutil 2000 100
* jmap
* jinfo [查看参数例子](http://file.bmob.cn/M00/03/AD/wKhkA1PE2MGAB4-fAAGTqUeu-cE940.png)
* jstack
* jvisualvm/jconsole
* mat(MemoryAnalyzer)
* btrace
* jclasslib（查看局部变量表）

前段时间，接手(前面已经有成型的东西)使用Hadoop存储转换的项目，但是生产环境的程序总是隔三差五的OOM，同时使用的hive0.12.0也偶尔出现内存异常。这对于运维来说就是灭顶之灾！搞不好什么时刻程序就挂了！！必须咬咬牙把这个问题处理解决，开始把老古董们请出来，翻来基本不看的后半部分--Java内存管理。

* 《Java程序性能优化-让你的Java程序更快、更稳定》第5章JVM调优/第6章Java性能调优工具
* 《深入理解Java虚拟机-JVM高级特性与最佳实践》第二部分自动内存管理机制

这里用到的理论知识比较少。主要用Java自带的工具，加上内存堆分析工具（mat/jvisualvm）找出大对象，同时结合源代码定位问题。

下面主要讲讲实践，查找问题的思路。在本地进行测试的话，我们可以打断点，可以通过jvisualvm来查看整个运行过程内存的变化趋势图。但是到了linux服务器，并且还是生产环境的话，想要有本地一样的图形化工具来监控是比较困难的！一般服务器的内存都设置的比较大，而windows设置的内存又有限！所以内存达到1G左右，立马dump一个堆的内存快照然后下载到本地进行来分析（可以通过`-J-Xmx`[调整jvisualvm的内存](http://file.bmob.cn/M00/09/83/wKhkA1P7TV-ABDnOAAB-OnVBQic050.png)）。

* 首先，由于报错是在Configuration加载配置文件时抛出OOM，第一反应肯定Configuraiton对象太多导致！同时查看dump的堆内存也佐证了这一点。直接把程序中的Configuration改成单例。

程序对象内存占比排行（`jmap -histo PID`）：

![](http://file.bmob.cn/M00/09/81/wKhkA1P7S8yARYSkAAiFW9cVN5w526.png)

使用mat或者jvisualvm查看堆，确实Configuration对象过多（`jmap -dump:format=b,file=/tmp/bug.hprof PID`）：

![](http://file.bmob.cn/M00/09/83/wKhkA1P7TbmAIdDEAAq3ktPBs6Q266.png)

* 修改后再次运行，但是没多大用！还是OOM！！

* 进一步分析，发现在Configuration中的属性/缓冲的都是弱引用是weakhashmap。

![](http://file.bmob.cn/M00/09/83/wKhkA1P7TfaAf4nwAAbcdgFiyXs804.png)

OOM最终问题不在Configuration对象中的属性，哪谁hold住了Configuration对象呢？？

* 再次从根源开始查找问题。程序中FileSystem对象使用`FileSystem.get(URI, Configuration, String)`获取，然后调用`get(URI,Configuration)`方法，其中的**CACHE**很是刺眼啊！

![](http://file.bmob.cn/M00/09/8D/wKhkA1P72pmAAMdnAAEYMjHFUAI853.png)

缓冲FileSystem的Cache对象的Key是URI和UserGroupInformation两个属性来判断是否相等的。对于一个程序来说一般就读取一个HDFS的数据即URI前部分是确定的，重点在UserGroupInformation是通过`UserGroupInformation.getCurrentUser()`来获取的。

即获取在get时`UserGroupInformation.getBestUGI`得到的对象。而这个对象在UnSecure情况下每次都是调用`createRemoteUser`创建新的对象！也就是每调用一次`FileSystem.get(URI, Configuration, String)`就会缓存一个FileSystem对象，以及其hold住的Configuration都会被保留在内存中。
![](http://file.bmob.cn/M00/09/82/wKhkA1P7TBSAaYEoAAhzUA5j5MI991.png)

![](http://file.bmob.cn/M00/09/82/wKhkA1P7TJ2AfwJzAAhEVFjK7Ek367.png)

只消耗不释放终究会坐吃山空啊！到最后也就必然OOM了。从mat的UserGroupInformation的个数查询，以及Cache对象的总量可以印证。

![](http://file.bmob.cn/M00/09/82/wKhkA1P7TNeAB7JAAAdMg-udeR8285.png)

![](http://file.bmob.cn/M00/09/83/wKhkA1P7TU-ACoaCAApK4n-52hI027.png)

## 问题处理

把程序涉及到FileSystem.get调用去掉user参数，使两个参数的方法。由于都使用getCurrentUser获取对象，也就是说程序整个运行过程中就一个FileSystem对象，但是与此同时就不能关闭获取到的FileSystem，如果当前运行的用户与集群所属用户不同，需要设置环境变量指定当前操作的用户！

```
System.setProperty("HADOOP_USER_NAME", "hadoop");
```

查找代码中调用了FileSystem#close是一个痛苦的过程，由于FileSystem实现的是Closeable的close方法，用**Open Call Hierarchy**基本是大海捞中啊，根本不知道那个代码是自己的！！这里用btrace神器让咋也高大上一把。。。

当时操作的步骤找不到了，下图是调用Cache#getInternal方法监控代码[GIST](https://gist.github.com/winse/161f6fe9120f2ec6b024)：

![](http://file.bmob.cn/M00/09/84/wKhkA1P7UD2AFk2cAAXRQWzniL0296.png)

## hive0.12内存溢出问题

hive0.12.0查询程序MR内容溢出

![](http://file.bmob.cn/M00/09/81/wKhkA1P7StSAOgX1AAoW9v-Fd4s439.png)

在hive-0.13前官网文档中有提到内存溢出这一点，可以对应到FileSystem中代码的判断。

![](http://file.bmob.cn/M00/09/85/wKhkA1P7UP-ACRVdAAJHBKNTq94580.png)

```
	String disableCacheName = String.format("fs.%s.impl.disable.cache", scheme);
    if (conf.getBoolean(disableCacheName, false)) {
      return createFileSystem(uri, conf);
    }
```	

hive0.13.1处理

![](http://file.bmob.cn/M00/09/84/wKhkA1P7T_CAcxVqAARr7CGiDvY177.png)

![](http://file.bmob.cn/M00/09/84/wKhkA1P7T6KAKoUiAAvODPwh1po815.png)

新版本在每次查询（session）结束后都会把本次涉及到的FileSystem关闭掉。

![](http://file.bmob.cn/M00/09/84/wKhkA1P7T9uAQQB3AAWrj_efwZU495.png)

## 理论知识

从GC类型开始讲，对自动化内存的垃圾收集有个整体的感知： 新生代/s0（survivor space0、from space）/s1（survivor space1、to space）/永久代。虚拟机参数`-Xmx`,`-Xms`,`-Xmn`（`-Xss`）来调节各个代的大小和比例。

* `-Xss` 参数来设置栈的大小。栈的大小直接决定了函数的调用可达深度
* `-XX:PrintGCDetails -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=15 -Xms40m -Xmx40m -Xmn20m`
* `-XX:NewSize`和`-XX:MaxNewSize`
* `-XX:NewRatio`和`-XX:SurvivorRatio`
* `-XX:PermSize=2m -XX:MaxPermSize=4m -XX:+PrintGCDetails`
* `-verbose:gc`
* `-XX:+PrintGC`
* `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/bug.hprof -XX:OnOutOfMemoryError=/reset.sh`
* `jmap -dump:format=b,file=/tmp/bug.hprof PID`
* `jmap -histo PID > /tmp/s.txt`
* `jstack -l PID`

