---
layout: post
title: "使用 Eclipse 远程调试 Java 应用程序"
time: 2012-10-08 20:20
comments: true
categories: [java]
---


## 普通Java程序：

1、导出包括调试信息的jar工程

在eclipse中，选择**Window > Preferences > Java > Compiler**来修改设置。 全选**Classfile Generation**选项卡内的选项(这里的选项是为了能把Debug需要的信息也写入到class字节码文件[d1])。然后从eclipse导出工程为remoting-debug.jar。

2、服务器运行

```
java -Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=8000 -jar remoting-debug.jar
```

3、本地调试

运行后，选择 **Run>Debug Configurations...>Remote Java Application** 运行就可以远程调试了。

* 在**Project**选项卡选择需要调试的project。（其实只要选择其中一个你要调试的的project即可）
* **Connection Type**为_Standard （Socket Listen）_
* **Port**为address的值_8000_

![](http://dl.iteye.com/upload/attachment/0080/2115/ce34010c-23e4-3d90-831f-92b9d13aeea0.png)

## Tomcat应用：

1、在startup.bat的":end"前增加

```
set JPDA_TRANSPORT=dt_socket
set JPDA_ADDRESS=8000
set JPDA_SUSPEND=y

call "%EXECUTABLE%" jpda start %CMD_LINE_ARGS%

```

![](http://dl.iteye.com/upload/attachment/0080/2117/ae1b16db-2b3c-3014-8e01-bba8d3a74faf.png)

以上设置的这些参数最终在catalina.bat中被调用！

2、参考【java程序】的[步骤3]的操作。 在eclipse里面的设置和上面的java相同。

## 调试的时刻源码行号对不上

> Eclipse下Debug时弹出错误“Unable to install breakpoint due to missing line number attributes,Modify compiler options togenerate line number attributes" 
>  
> 遇到这个错误时找到的解答方案汇总： 
>
> 1. 使用Ant编译时，未打开debug开关，在写javac 任务时确认debug=true，否则不能调试。THe settings for the eclipse compiler don't affect the ant build and even if you launch the ant build from within eclipse. ant controls it's own compiler settings.you can tell ant to generate debugging info like this 'javac ... debug="true".../>（我的问题是因为这个原因）； 
>
> 2. 编译器的设置问题，window->preferences->java->Compiler在compiler起始页，classfile Generation区域中确认已经勾选了All line number attributes to generated class files。如果已经勾选，从新来一下再Apply一下。或者从项目层次进行设定，项目属性->java compiler同样在起始页，确定已经勾选 
> 
> Eclipse报的这个错，无非就这两个原因造成的
>

## 参考：

* [Eclipse调试常用技巧](http://www.iteye.com/topic/633824)
* <http://www.iteye.com/topic/633824>
* http://www.ibm.com/developerworks/cn/opensource/os-eclipse-javadebug/
* http://yiminghe.iteye.com/blog/1027707
* http://www.oschina.net/question/54100_10243
* http://www.cnblogs.com/sos-blue/archive/2012/01/05/2313047.html
  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1693859)
