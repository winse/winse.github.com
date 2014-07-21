---
layout: post
title: "使用hadoop-eclipse-plugin插件"
date: 2013-03-27 01:16
comments: true
categories: [hadoop]
---

一直使用hadoop但都没有用过hadoop-plugins插件，倒不是看不上这个插件的意思。只是个人感觉使用SecureCRT太好用了。上传一个jar直接一拉进去使用lrzsz（z-moden）就直接搞定了。

但，身边搞hadoop的大部分都使用，今天略有兴致的弄了一弄，把环境hadoop-eclipse-plugins整起来了。在公司本来就使用插件来开发的，同时也看看Run-on-Hadoop的大致的实现。

## 环境准备：

* eclipse-jee-3.7
* jdk7
* hadoop-1.0.0

## 插件编译-导出-安装

打开eclipse，把hadoop-1.0.0\src\contrib\eclipse-plugin整个工程导入（本来就是一个eclipse的project）。工程的lib目录下面已经包括了hadoop-core-1.0.0.jar包，但是hadoop-core-1.0.0.jar需要其他的依赖的jar包。我把这些依赖的jar从hadoop-1.0.0\lib下面复制到eclipse的/MapReduceTools/lib目录下。

然后，打开eclipse的/MapReduceTools/META-INF/MANIFEST.MF文件，切换到Runtime标签页，在classpath区域点击“Add...”添加lib下面的所有jar。

![](http://dl.iteye.com/upload/attachment/0082/2577/d8eb44b7-008d-3bbb-9695-d4d200432100.png)

然后，再切换到Overview标签页，导出插件。

![](http://dl.iteye.com/upload/attachment/0082/2579/d631e742-2d17-3fe8-8fdc-04617b2ff7f6.png)

导出以后，把导出的插件拷贝都**eclipse/dropins**目录下。

![](http://dl.iteye.com/upload/attachment/0082/2568/bfa52d58-6556-3419-8d90-1a129d637b7d.png)

然后重启。

## 配置环境：

1. 设置HADOOP_HOME的位置。

	设置Preferences中的Hadoop Map/Reduce的**Hadoop installation directory**为你hadoop的主目录。我这里是C:\cygwin\home\Winseliu\hadoop-1.0.0（主要是用来把hadoop/lib下的包加入到MapRed Project的classpath）。

2. 切换到Mapreduce透视图（Window | Open Perspective | other | Map/Reduce），然后新建一个Hadoop Location。操作如图：

	![](http://dl.iteye.com/upload/attachment/0082/2570/39e0d163-8a83-36ae-9896-50a0fb5e087b.png)

3. 然后，如果集群启动了，就可以看到下图的效果了。

	![](http://dl.iteye.com/upload/attachment/0082/2572/370005b7-3ccf-30c0-832f-8f987cb8f426.png)

	mapred插件提供的MapReduce Driver类还是不错的，把从写JobMain繁琐的工作中稍稍解放了一点。

	![](http://dl.iteye.com/upload/attachment/0082/2581/662d38e3-2196-3daf-814a-1a217d4e9892.png)

## Run-on-Hadoop的实现

一般我们在设置Job（JobConf）.setJarByClass(WordCount.class)都是设置Main对应的主类。

查看源码，就可以得知。其实最终，设置了conf的**mapred.jar**属性！在提交的job时刻，会把该属性对应的jar拷贝到HDFS，最后发布到每台运行的机器上。

![](http://dl.iteye.com/upload/attachment/0082/2599/f1c7a584-a703-3850-aaf0-6189e81897fa.png)

![](http://dl.iteye.com/upload/attachment/0082/2594/7af83776-ebcd-3783-8101-4b3ec748e6cc.png)

所以，也就是说，只要把需要的**class导出为jar**，然后把该**jar对应的路径给mapred.jar的属性**即可。

理着这思路，在源码中有org.apache.hadoop.eclipse.server.JarModule类调用JDT的JarPackageData来处理jar的导出工作。

JarModule类在`org.apache.hadoop.eclipse.servers.RunOnHadoopWizard.performFinish()`方法中被调用。也就是点击Run-on-Hadoop菜单后弹出的对话框的**Finish按钮**被点击时。

![](http://dl.iteye.com/upload/attachment/0082/2605/cccce4cc-1056-3315-bcdc-1c9453fdb23a.png)

然后，会把该jar的路径写入到core-site.xml的配置文件中。该core-site.xml文件的路径会被加入到classpath，也就说Main方法的Configuration会加载这个配置文件！把conf的目录加入到classpath:

```
      classPath =
          iConf.getAttribute(
              IJavaLaunchConfigurationConstants.ATTR_CLASSPATH,
              new ArrayList());
	  IPath confIPath = new Path(confDir.getAbsolutePath());
      IRuntimeClasspathEntry cpEntry =
          JavaRuntime.newArchiveRuntimeClasspathEntry(confIPath);
      classPath.add(0, cpEntry.getMemento());
```

后面的步骤就和一个普通的java类被调用一样的效果咯！

发布到集群运行的包涉及影响的文件：

![](http://dl.iteye.com/upload/attachment/0082/2638/d113ef06-1bbb-387f-9ebe-e7e4580c023b.png)

## 参考资源：

* <http://my.oschina.net/zhujinbao/blog/56236>

  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1837035)
