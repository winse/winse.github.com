---
layout: post
title: Tomcat源码阅读-批处理解读
date: 2014-3-15 10:03:03
---

### 常用Tomcat批处理文件

在windows系统下，双击bin/startup.bat即可启动tomcat。但核心的批处理文件是**catalina.bat**，最终调用的就是catalina.bat文件。

version.bat、shutdown.bat、startup.bat、configtest.bat都只是增加version/stop/start/configtest命令参数，然后调用catalina.bat批处理文件。

### catalina.bat

批处理文件中最重要的非catalina.bat莫属了！包含非常多的操作！

#### 1 关闭优化

** Suppress(止住) Terminate batch job on CTRL+C **

在第一个参数`%1`为run操作时，同时拥有%TEMP%目录写权限，执行`call "%~f0" %* <"%TEMP%\%~nx0.Y"`，好像也就是调用自身，如果检测到`"%TEMP%\%~nx0.run"`存在就跳到脚本主体去执行。完成后退出。**Tomcat7才加上的！**

在按了CTRL+C后，**去掉提示用户确认操作**！！！对比下Tomcat6和Tomcat7一切都明白了！在命令行里面调用call的重定向输入`%TEMP%\%~nx0.Y`的就是Y！！就是提示行的输入啊！

> Suppress anoying Terminate batch job prompt when hitting CTRL+C. Note however that it leaves the file named yes in the bin directory
>
> git-svn-id: https://svn.apache.org/repos/asf/tomcat/trunk@922223 13f79535-47bb-0310-9956-ffa450edef68

#### 2 验证主目录

* 获取CATALINA_HOME
	- CATALINA_HOME环境变量存在
	- 当前目录`%cd%`，如果`%CATALINA_HOME%\bin\catalina.bat`存在，跳到**验证EXECUTABLE**操作
	- 当前目录父目录。
	
* 验证CATALINA_HOME

	如果`%CATALINA_HOME%\bin\catalina.bat`不存在，打印错误信息，退出

* 验证EXECUTABLE

	其实就是验证%CATALINA_HOME%\bin\catalina.bat是否存在（个人觉得相当多余，到达这一部，已经保证了catalina.bat的存在）。
	
	不存在则报错。每个文件都要获取并设置CATALINA_HOME，其实shell的sh文件也一样，每个sh文件都需要获取一遍当前dirname。

#### 3 设置环境变量/参数

* 设置CATALINA_BASE为CATALINA_HOME（如果没定义）
* 调用setenv.bat脚本设置环境变量（如果存在）。先检测调用CATALINA_BASE目录下的，没有才调用CATALINA_HOME下的。
* 调用CATALINA_HOME下面的setclasspath.bat脚本（必须存在，否则会报错退出）
* 获取CLASSPATH，并添加bootstrap.jar
* 设置CATALINA_TMPDIR为`%CATALINA_BASE%\temp`（如果没定义）
* 如果tomcat-juli.jar存在则添加到CLASSPATH
* 把`%LOGGING_CONFIG%`加入JAVA_OPTS
	1. `%LOGGING_CONFIG%`
	2. `-Dnop`
	3. `-Djava.util.logging.config.file="%CATALINA_BASE%\conf\logging.properties"`
* 把`%LOGGING_MANAGER%`加入JAVA_OPTS
	1. `%LOGGING_MANAGER%`
	2. `-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager`
* 输出环境变量信息

#### 4 组装执行命令

接下来的变量直接牵涉到怎么去运行tomcat！ 这些变量包括： MAINCLASS、ACTION、JDPA、_EXECJAVA、SECURITY_POLICY_FILE

* MAINCLASS设置了Java调用的主类org.apache.catalina.startup.Bootstrap

	除了version直接调用org.apache.catalina.util.ServerInfo外，其他命令的入口都是这个类。

* ACTION默认的操作为start

	另外命令对应是stop/configtest。

* JDPA([Java Platform Debugger Architecture](http://www.ibm.com/developerworks/cn/java/j-lo-jpda1/))

	使用`jpda [start|run|stop|configtest]`即可启用远程调试功能。默认为`-agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=n`。也可以通过JPDA_TRANSPORT，JPDA_ADDRESS，JPDA_SUSPEND环境变量来指定部分参数，或者直接指定JPDA_OPTS完整的JPDA选项。

* _EXECJAVA： 默认为`%_RUNJAVA%`，debug时设置为`%_RUNJDB%`，start时指定TITLE设置为`start "%TITLE%" %_RUNJAVA%`。
* SECURITY_POLICY_FILE： debug/run/start后跟`-security`时，设置为`%CATALINA_BASE%\conf\catalina.policy` [TODO]

最后就是_EXECJAVA、Jpda、Security进行组合来执行调用Java类，`ACTION`作为最后一个参数传给java的main方法。	

**其他一些参数可以通过JAVA_OPTS，CATALINA_OPTS环境变量指定。**

* * *

### 其他注意点

* 如果第一个参数为debug命令，一定要用JDK！

	在打印输出信息的时刻，会输出JAVA_HOME，而不是JRE_HOME

	看到的一些不足：
在打印信息的时刻，%1判断是否为debug。接下来检测取出jpda，再判读其他执行操作（debug/run/start/configtest/stop/version）。
但是呢，jdpa后不能跟debug的！执行了`catalina.bat debug`会调用jdb，而 -agentlib:jdwp不在jdb允许的选项之列！

* 网上很多教程都是，安装tomcat都会去设置环境变量！

	JAVA_HOME和TOMCAT_HOME的环境变量（全局），其实可以在startup.bat中设置即可（本地）。这样，可以很好的运行多个不同版本的tomcat。

* run和start的区别

	start命令会`start %_RUNJAVA%`另起一个进程，而run是直接调用`%_RUNJAVA%`。
在windows系统start命令会弹出一个新窗口，但是在linux下面start会在调用的时刻添加`&`后台运行，打印的信息都得去日志文件中查看。

