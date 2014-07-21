---
layout: post
title: Tomcat源码阅读-环境搭建
description: Tomcat源代码环境搭建
keywords: eclipse, tomcat
date: 2013-08-30 20:22:58
---

很早就买了《深入剖析Tomcat》这本书，但是一直没有下定决心去看tomcat的源码    
在工作中大部分时间都是使用tomcat作为容器，整体来说对tomcat还是有所了解，有那么点好奇，还是想好好的深入的了解下Tomcat。
    
既然要读源码，第一步就是检出源码，配置环境。

## 下载源码

打开Eclipse的git视图，下载源码https://github.com/apache/tomcat.git 
然后检出TOMCAT_7_0_42的Tag。

## 生成eclipse的工程文件

执行Ant的Target为ide-eclipse任务。正常完成后，会在tomcat工作目录下生成eclipse工程需要的.project和.classpath两个文件。

	D:\top_projects\tomcat>ant ide-eclipse
	...
	downloadfile:
	    [mkdir] Created dir: D:\usr\share\java\wsdl4j-1.6.2
	      [get] Getting: http://repo.maven.apache.org/maven2/wsdl4j/wsdl4j/1.6.2/wsdl4j-1.6.2.jar
	      [get] To: D:\usr\share\java\wsdl4j-1.6.2\wsdl4j-1.6.2.jar
	     [copy] Copying 1 file to D:\top_projects\tomcat\output\extras\webservices
	     [copy] Copying 1 file to D:\top_projects\tomcat\output\extras\webservices
	
	ide-eclipse:
	     [copy] Copying 1 file to D:\top_projects\tomcat
	     [copy] Copying 1 file to D:\top_projects\tomcat
	     [echo] Eclipse project files created.
	     [echo] Read the Building page on the Apache Tomcat documentation site for details on how to configure your Eclipse
	workplace.
	
	BUILD SUCCESSFUL
	Total time: 2 minutes 47 seconds

在Git Repositories视图，右键Working Directory节点，然后选择Import Projects到eclipse工作区即可。

## 依赖jar处理

在导入为eclipse工程后，出现了ANT_HOME和TOMCAT_LIBS_BASE的classpath依赖的错误，导致整个工程不能编译    
在生成eclipse工程文件的步骤时，有下载编译依赖的jar，我们需要把这些jar路径告诉eclipse-classpath    

选择`Preferences -> Java -> Build Path -> Classpath Variables`， **添加ANT_HOME和TOMCAT_LIBS_BASE的两个路径。**

其中TOMCAT_LIBS_BASE为build.properties.default文件中base.path指定的路径； 
确定后即可找到依赖的jar。

## 小结

Tomcat的开发环境的搭建，由于提供了Ant的脚本，所以配置还是比较简单。需要注意的就是配置两个额外eclipse的classpath参数即可。
搭建好了环境，下一篇穿插讲讲是脚本的启动。这样才知道Tomcat是调用哪个主类来启动Tomcat系统的！
