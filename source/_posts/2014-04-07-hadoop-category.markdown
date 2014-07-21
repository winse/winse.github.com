---
layout: post
title: "hadoop2学习过程/资源"
date: 2014-4-21 22:37:20
categories: [hadoop]
---

接触集群，起始为毕业论文觉得做一个SSH的内容管理系统觉得无趣，选择了Hadoop相关的选题。尽管做的很烂，但是当时做出来一个东西还是挺开心的。中间断了近一年，但是在鼎象做游戏的时刻部署系统/维护查日志，对linux熟悉了不少。在科韵开始做插件开发，神马都的看源码。而后，真正的做了一个hadoop的项目，相比2年前，对编程和学习的方式都有了提升。hadoop，kettle这些都是很牛掰的很火热软件，但是中文资料相对较少，变化也很快。慢慢的觉得自己看代码和英文的资源都过得去。

再碌碌无为的过了一年，而今又接触hadoop，时代变了，但是基本的技术还是相同的。从hadoop1升级到hadoop2，尽管变化很大，熟悉的过程中再次遇到很多的问题。觉得无能无力，原来的日子好似白过了！记录是一种美德，不仅是走过路过的足迹，亦是摘树后人乘凉的盛举。

要弄hadoop，首先得把对english的偏见放下！如果还是baidu查找你遇到的问题，那或许你会多走很多的弯路！

## 书籍

开始还是推荐下中文资料：

* [Hadoop权威指南/Hadoop The Definitive Guide] 大师写的书，值的膜拜 
* [hadoop实战/Hadoop in Action] 相对来说是也是一本不错的 

## 网页资源

1. Linux部署Hadoop
	* [Hadoop Tutorial - YDN](http://developer.yahoo.com/hadoop/tutorial/)
	* [Hadoop-2.2.0集群安装配置实践](http://shiyanjun.cn/archives/561.html)
	* [hadoop2.2.0 单机伪分布式（含64位hadoop编译）及 eclipse hadoop开发环境搭建](http://www.cnblogs.com/i80386/p/3548132.html)
2. Windows部署Hadoop
	* [配置Cygwin支持无密码SSH登陆](http://yangshangchuan.iteye.com/blog/1839812)
	* [Hadoop2OnWindows - Hadoop Wiki](http://wiki.apache.org/hadoop/Hadoop2OnWindows)
	* [[MAPREDUCE-5655] job submit from windows to a linux hadoop cluster fails due to wrong classpath](https://issues.apache.org/jira/browse/MAPREDUCE-5655)
	* [linux - what does "bash:no job control in this shell” mean? - Stack Overflow](http://stackoverflow.com/questions/11821378/what-does-bashno-job-control-in-this-shell-mean)
	* [Running Apache Hadoop 2.1.0 on Windows - Stack Overflow](http://stackoverflow.com/questions/18630019/running-apache-hadoop-2-1-0-on-windows)
	* [Error 'LINK : fatal error LNK1123: failure during conversion to COFF: file invalid or corrupt'](http://stackoverflow.com/questions/10888391/error-link-fatal-error-lnk1123-failure-during-conversion-to-coff-file-inval)
	* [VS2010 error: LINK : fatal error LNK1123: failure during conversion to COFF: file invalid or corrupt](http://blog.csdn.net/xzz_hust/article/details/9450289)
	* [[HADOOP-10144] Error on build in windows 7 box](https://issues.apache.org/jira/browse/HADOOP-10144)
	* [Build, Install, Configure and Run Apache Hadoop 2.2.0 in Microsoft Windows OS](http://www.srccodes.com/p/article/38/build-install-configure-run-apache-hadoop-2.2.0-microsoft-windows-os#comment-1150229068)
	* [hadoop2.2.0遇到NativeLibraries错误的解决过程](http://blog.csdn.net/bamuta/article/details/13506843)
	* [hadoop2.2.0遇到64位操作系统平台报错，重新编译hadoop](http://blog.csdn.net/bamuta/article/details/13506893)
	* [Hadoop "Unable to load native-hadoop library for your platform" error on CentOS](http://stackoverflow.com/questions/19943766/hadoop-unable-to-load-native-hadoop-library-for-your-platform-error-on-centos)
3. eclipse直接访问HDFS/提交任务
	* [Hadoop学习三十二：Win7下无法提交MapReduce Job到集群环境](http://zy19982004.iteye.com/blog/2031172)
	* [Eclipse调用hadoop2运行MR程序](http://blog.csdn.net/fansy1990/article/details/22896249)
4. cygwin部署hadoop
	* [cygwin sshd 安装配置](http://blog.csdn.net/needle2/article/details/5416571)
	* [如何确定自己是否已接入IPv6网络及故障分析（提问必看）](http://www.ipv6bbs.cn/thread-209-1-1.html)
	* [在IPv4网络下接入IPv6网络的方法（隧道与第三方软件）](http://www.ipv6bbs.cn/thread-151-1-1.html)
5. hdfs脚本文件系统
6. 编译源码
	* [maven工程pom添加log4j依赖 Missing artifact javax.jms:jms:jar:1.1:compile 为pom.xml添加dependency，编译报错缺少jar包，但是本地库中有这个包](http://blog.163.com/universsky@126/blog/static/112760232201362743156735/)
	* [找不到org.mortbay.component.AbstractLifeCycle的类文件](http://www.cnblogs.com/sysuys/p/3492791.html)
	* [[HADOOP-10110]hadoop-auth has a build break due to missing dependency](https://issues.apache.org/jira/browse/HADOOP-10110)
	* [Hadoop CDH5 手动安装伪分布式模式 ](http://blog.csdn.net/superye1983/article/details/16884097)
7. 远程调试
	* [Remote debugging a Java application](http://stackoverflow.com/questions/975271/remote-debugging-a-java-application)
	* [Eclipse调试框架的学习与理解](http://liugang594.iteye.com/blog/154710)
	* [Java的远程debug](http://duming115.iteye.com/blog/791218)
	* [使用 Eclipse 远程调试 Java 应用程序](http://www.ibm.com/developerworks/cn/opensource/os-eclipse-javadebug/index.html)
8. 与正式环境有关
	* [putty – 使用putty命令行参数](http://cn.mzcart.com/2012/04/24.html)
	* [Windows下使用ssh代理来访问国外的youtube和twitter/fackbook等网站](http://www.ctohome.com/FuWuQi/0b/301.html)
	* [使用SecureCRT的SSH端口转发，使用PLSQL访问内网数据库](http://hejianhuacn.iteye.com/blog/1972033)
	* [用ssh端口转发功能访问远程服务器](http://qn-lf.iteye.com/blog/859662)
	* [SecureCRT设置SSH端口转发详解](http://blog.csdn.net/linuxoostudy/article/details/7097418)
9. 开发参考的资源/代码访问集群
	* [Hadoop 新 MapReduce 框架 Yarn 详解](http://www.ibm.com/developerworks/cn/opensource/os-cn-hadoop-yarn/)
	* [Hadoop 2.0中作业日志收集原理以及配置方法](http://dongxicheng.org/mapreduce-nextgen/hadoop-2-0-jobhistory-log/)
	* [Hadoop日志到底存在哪里？](http://dongxicheng.org/mapreduce-nextgen/hadoop-logs-placement/)
	* [Hadoop DistributedCache详解](http://dongxicheng.org/mapreduce-nextgen/hadoop-distributedcache-details/)
	* [Hadoop DistributedCache使用及原理](http://hpuxtbjvip0.blog.163.com/blog/static/3674131320132794940734/)

## 工具

* lrzsz
* SecureCRT
* WinSCP
* w3m # 最后使用SSH代理访问取代！

## 思维

* 化整为零

## 技巧

* 查看jar列表：`jar tvf JAR`
* ssh-copy-id
* rsync
* find
* ls -Sl
* while/for
* `cat unknown.txt | cut -b 62- | sort | uniq`

- 持续的更新 - 
