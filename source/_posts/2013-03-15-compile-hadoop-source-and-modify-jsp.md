---
layout: post
title: "编译hadoop的jsp源码"
date: 2013-03-15 23:21
comments: true
categories: [hadoop]
---

从apache下载的tar.gz的hadoop-1.1.0包中本来就包括了src的源码。可以方便我们查看源码调试。

~~题外话： 从github上下载了最新的hadoop-common的源码，发现hadoop-2.0已经是使用maven管理代码了。~~

在eclipse中新建java project，去掉**Use Default location**的复选框的勾，项目目录为hadoop-1.1.0程序所在的位置。然后点击finish即可。

![](http://dl.iteye.com/upload/attachment/0081/7334/643c83b4-e123-362e-bc40-d801805584f4.png)

完成后，项目下面的lib包，以及Source Folder源码包都已经正确的配置好了。如下图。

![](http://dl.iteye.com/upload/attachment/0081/7344/64575adf-3ee5-3a83-a184-bcff4f9df4d8.png)

编译hadoop的源码，需要用到sed，sh的linux shell命令（根据网上的资料）。安装好了cygwin，把c:\cygwin\bin加入到PATH环境变量。然后直接使用eclipse ant（eclipse自带）编译。

```
Winseliu@WINSE ~
$ cygcheck -c cygwin
Cygwin Package Information
Package              Version        Status
cygwin               1.7.17-1       OK

```

![](http://dl.iteye.com/upload/attachment/0081/7351/e1b2d853-fcaf-3ccc-8663-8f579c67755f.png)

由于linux和windows的换行符的不同（同事周帅哥在导数据也遇到这样的问题），直接编译会失败。

![](http://dl.iteye.com/upload/attachment/0081/7353/29b31fa1-7f02-3979-b72d-fc3019f355dd.png)

需要对src/saveVersion.sh的shell文件进行修改：

```
-  user=`whoami`
+  user=`whoami | tr -d '\r'` 
```

然后再编译一次就ok了！

- - - - - 

经过上面步骤已经可以正确的编译hadoop-core的源码了。

在监控集群的时刻，我们一般都在自己常用的windows系统上面通过50030和50070来了解集群的情况。但是如果没有域名服务器，那，我们就不得不修改hosts文件。在出现访问失败的情况下，我们可以使用ip地址替换URL中对应的hostname来访问，但是比较麻烦。

如果在服务器响应请求的时刻，解析生成html的时刻就已经是ip地址那就最好不过了！
其实，直接看看jsp的源码，修改起来不算太难。把jsp里面的hostname转换为IP地址即可。

![](http://dl.iteye.com/upload/attachment/0081/7361/951ae5f2-9dc3-31cd-aef3-657608a93e00.png)

把上图的hostname通过InetAddress获取转换为IpAddress地址。

```
-    String namenodeHost = jspHelper.nameNodeAddr.getHostName();
+    String namenodeHost = jspHelper.nameNodeAddr.getAddress().getHostAddress();

-              InetAddress.getByName(namenodeHost).getCanonicalHostName() + ":" +
+              InetAddress.getByName(namenodeHost).getHostAddress() + ":" +

```

全部修改完成后，再次运行hadoop-1.1.0 build.xml的ant命令，会调用自定义的jsp-compile把jsp转换成java类保存到build/src目录下面。然后javac再编译build/src目录下的源码。

![](http://dl.iteye.com/upload/attachment/0081/7370/421dc6d3-4a8a-340a-8bca-705369c0a057.png)

如果你只想编译这些jsp，把javac中的srcdir的目录只保留build.src应该就可以咯。

我是直接把build/src作为Source Folder，然后把这个Source Folder下的编译文件放置的特定的目录，然后覆盖原来jar里面的class即可！

![](http://dl.iteye.com/upload/attachment/0081/7396/7b3ccd33-936a-30ce-8082-d82f34d768bf.png)

## 参考：

* [Hadoop源代码eclipse编译教程](http://wenku.baidu.com/view/c1ad44323968011ca3009199.html)


* * * 
[【原文地址】](http://winse.iteye.com/blog/1830311)
