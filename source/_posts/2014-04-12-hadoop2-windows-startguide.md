---
layout: post
title: "Windows下部署/配置/调试hadoop2"
date: 2014-4-21 8:27:11
categories: [hadoop]
---

Windows作为开发屌丝必备，在windows上如何跑集群方便开发调试，以及怎么把eclipse写好的任务mapreduce提交到测试的集群(linux)上面去跑？这些都是需要直面并解决的问题。

本文主要记录在windows上hadoop集群的环境准备，以及eclipse调试功能等。

1. windows伪分布式部署
	* cmd
	* cygwin shell
2. windows-eclipse提交任务到linux集群
3. 导入源码到eclipse

部署的基本操作，以及在linux如何部署环境，请查阅[linux配置hadoop2环境]({{ BASE_PATH }}{{ page.previous.url }})。

这篇文章并非按照操作的时间顺序来进行编写。而是，如果再安装第二遍的话，自己应该如何去操作来组织下文。

## 一、Windows伪分布式部署

尽管一直用windows，但是对windows自带的cmd命令很是不屑！想在cygwin下部署，现在想来，最终用的是windows的java！在cygwin下不就是把路径转换后再传给java执行吗！

所以，如果把cygwin环境搭建好了的话，其实已经把windows的环境也搭建好了！同样hadoop的windows环境配置好了，cygwin环境也同样配置好了。但是，在cygwin下面提交mapreduce任务会有各种"凌乱"的问题！

先说说在windows环境搭建的步骤，然后再讲cygwin下运行。

1. 需要用到的软件环境
2. 编译windows环境变量配置
3. 编译hadoop-common源代码生成本地依赖库
4. 伪分布式配置
5. windows下运行
6. cygwin下运行

### 1.1 需要用到的软件环境

* Win7-x86
* hadoop-2.2.0.tar.gz
* git
* cygwin (源码编译时需要执行sh命令)
* visual studio 2010（如果与.net framework4有关的问题请查阅： [[*]][winutils_lnk1123_1] [[*]][winutils_lnk1123_2] [[*]][winutils_lnk1123_3]）
* protoc(protoc-2.5.0-win32.zip)(**解压，然后把路径加入到PATH**)

搭建环境之前，**建议您看看[wiki-Hadoop2OnWindows][]**。最终有用的步骤都在上面了！不过在自己瞎折腾的过程中也弄了不少东西，记录下来！

### 1.2 编译windows环境变量配置 

| 变量              | windows
|:------------------|:---------------------------------------
| Platform          | Win32
| ANT_HOME          | D:\local\usr\apache-ant-1.9.0
| MAVEN_HOME        | D:\local\usr\apache-maven-3.0.4
| JAVA_HOME         | D:\Java\jdk1.7.0_02
| PATH              | C:\cygwin\bin;C:\protoc;D:\local\usr\apache-maven-3.0.4\bin;D:\local\usr\apache-ant-1.9.0/bin;D:\Java\jdk1.7.0_02\bin;%PATH%

~~编译时，在打开的命令行加入cygwin的路径即可。~~
在maven编译最后需要用到sh的shell命令，需要把`c:\cygwin\bin`目录加入到path环境变量。
这里先不配置hadoop的环境变量，因为我只需要用到编译后的本地库而已！！

### 1.3 编译源代码生成本地依赖库(dll, exe)

hadoop2.2.0操作本地文件针对平台的进行了处理。也就是只要在windows运行集群，不管怎么样，你都得先把winutils.exe、hadoop.dll编译出来，用来处理对本地文件赋权、软链接等（类似Linux-Shell的功能）。否则会看到下面的错误：

* 命令执行出错，少了winutils.exe
	
	```
	14/04/14 20:07:58 ERROR util.Shell: Failed to locate the winutils binary in the hadoop binary path
	java.io.IOException: Could not locate executable null\bin\winutils.exe in the Hadoop binaries.
		at org.apache.hadoop.util.Shell.getQualifiedBinPath(Shell.java:278)
		at org.apache.hadoop.util.Shell.getWinUtilsPath(Shell.java:300)
		at org.apache.hadoop.util.Shell.<clinit>(Shell.java:293)

	14/04/17 21:22:32 INFO service.AbstractService: Service org.apache.hadoop.yarn.server.nodemanager.LocalDirsHandlerServic
	e failed in state INITED; cause: java.lang.NullPointerException
	java.lang.NullPointerException
			at java.lang.ProcessBuilder.start(ProcessBuilder.java:1010)
			at org.apache.hadoop.util.Shell.runCommand(Shell.java:404)
			at org.apache.hadoop.util.Shell.run(Shell.java:379)
			at org.apache.hadoop.util.Shell$ShellCommandExecutor.execute(Shell.java:589)
			at org.apache.hadoop.util.Shell.execCommand(Shell.java:678)
			at org.apache.hadoop.util.Shell.execCommand(Shell.java:661)
			at org.apache.hadoop.fs.RawLocalFileSystem.setPermission(RawLocalFileSystem.java:639)
			at org.apache.hadoop.fs.RawLocalFileSystem.mkdirs(RawLocalFileSystem.java:435)
	```

* 少了hadoop.dll的本地库文件
	
	```
	14/04/17 21:30:27 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-ja
	va classes where applicable
	14/04/17 21:30:29 FATAL datanode.DataNode: Exception in secureMain
	java.lang.UnsatisfiedLinkError: org.apache.hadoop.io.nativeio.NativeIO$Windows.access0(Ljava/lang/String;I)Z
			at org.apache.hadoop.io.nativeio.NativeIO$Windows.access0(Native Method)
			at org.apache.hadoop.io.nativeio.NativeIO$Windows.access(NativeIO.java:435)
			at org.apache.hadoop.fs.FileUtil.canRead(FileUtil.java:977)
			at org.apache.hadoop.util.DiskChecker.checkAccessByFileMethods(DiskChecker.java:177)
			at org.apache.hadoop.util.DiskChecker.checkDirAccess(DiskChecker.java:164)
			at org.apache.hadoop.util.DiskChecker.checkDir(DiskChecker.java:147)
			at org.apache.hadoop.hdfs.server.datanode.DataNode$DataNodeDiskChecker.checkDir(DataNode.java:1698)
	```

#### 下载源码进行编译

下面需要用到visual studio修改项目配置信息（或者直接修改sln文件也行），然后再使用maven进行编译。

这里仅编译hadoop-common项目，最后把生成winutils.exe/hadoop.dll放到hadoop程序bin目录下。

第一步 下载源码

```
/*  https://github.com/apache/hadoop-common.git  */

Administrator@WINSELIU /e/git/hadoop-common (master)
$ git checkout branch-2.2.0
Checking out files: 100% (5536/5536), done.
Branch branch-2.2.0 set up to track remote branch branch-2.2.0 from origin.
Switched to a new branch 'branch-2.2.0'
```

第二步 应用补丁patch-native-win32

jira: https://issues.apache.org/jira/browse/HADOOP-9922		
patch: https://issues.apache.org/jira/secure/attachment/12600760/HADOOP-9922.patch

native.sln-patch有点问题下面通过vs修改，使用Visual Studio修改native的活动平台

![](http://farm4.staticflickr.com/3784/13895015882_c7cd95ece5_o.png)

第三步 在`Visual Studio 命令提示(2010)`命令行进行Maven编译(仅需编译hadoop-common)

![](http://farm4.staticflickr.com/3704/13918439233_8b2693c462_o.png)

```
E:\git\hadoop-common\hadoop-common-project\hadoop-common>mvn package -Pdist,native-win -DskipTests -Dtar -Dmaven.javadoc.skip=true

/*  native files  */

Administrator@winseliu /cygdrive/e/git/hadoop-common/hadoop-common-project/hadoop-common
$ ls -1 target/bin/
hadoop.dll
hadoop.exp
hadoop.lib
hadoop.pdb
libwinutils.lib
winutils.exe
winutils.pdb

Administrator@winseliu /cygdrive/e/git/hadoop-common/hadoop-common-project/hadoop-common
$ cp target/bin/* ~/hadoop/bin/
```

windows的本地库的路径就是PATH环境变量。所以**windows下最好还是把dll放到bin目录下，同时把`HADOOP_HOME/bin`加入到环境变量中！！**
修改PATH环境变量。

可以把dll放到自定义的位置，但是同样最好把该路径加入到PATH环境变量。java默认会到PATH路径下找动态链接库dll。

### 1.4 修改hadoop配置，部署伪分布式环境 

可以直接把linux伪分布式的配置cp过来用。然后修改namenode/datanode/yarn文件的存储路径就可以了。
这里有个坑，`hdfs-default.xml`中的路径前面都加了`file://`前缀！所以hdfs配置中涉及到路径的，这里都得进行了修改。

~~Notepad++的Ctrl+D是一个好功能啊~~

| 属性                                    | 值
|:----------------------------------------|:-------------------------
| **slaves**            
| localhost
| **core-site.xml**     
| fs.defaultFS                            | hdfs://localhost:9000
| io.file.buffer.size                     | 10240
| hadoop.tmp.dir                          | file:///e:/tmp/hadoop
| **hdfs-site.xml**      
| dfs.replication                         | 1
| dfs.namenode.secondary.http-address     | localhost:9001 #设置为空可以禁用
| dfs.namenode.name.dir                   | ${hadoop.tmp.dir}/dfs/name
| dfs.datanode.data.dir                   | ${hadoop.tmp.dir}/dfs/data
| dfs.namenode.checkpoint.dir             | ${hadoop.tmp.dir}/dfs/namesecondary
| ~~dfs.namenode.shared.edits.dir~~       | ${hadoop.tmp.dir}/dfs/shared/edits
| **mapred-site.xml**
| mapreduce.framework.name                | yarn
| mapreduce.jobhistory.address            | localhost:10020
| mapreduce.jobhistory.webapp.address     | localhost:19888
| **yarn-site.xml**
| yarn.nodemanager.aux-services           | mapreduce_shuffle
| yarn.nodemanager.aux-services.mapreduce_shuffle.class  | org.apache.hadoop.mapred.ShuffleHandler
| yarn.resourcemanager.address            | localhost:8032
| yarn.resourcemanager.scheduler.address  | localhost:8030
| yarn.resourcemanager.resource-tracker.address  | localhost:8031
| yarn.resourcemanager.admin.address      | localhost:8033
| yarn.resourcemanager.webapp.address     | localhost:8088
| yarn.application.classpath              | %HADOOP_CONF_DIR%, %HADOOP_COMMON_HOME%/share/hadoop/common/*, %HADOOP_COMMON_HOME%/share/hadoop/common/lib/*, %HADOOP_HDFS_HOME%/share/hadoop/hdfs/*, %HADOOP_HDFS_HOME%/share/hadoop/hdfs/lib/*, %HADOOP_YARN_HOME%/share/hadoop/yarn/*, %HADOOP_YARN_HOME%/share/hadoop/yarn/lib/*

注意点：

* yarn.application.classpath必须定义！尽管程序中有判断不同平台的默认值不同，但是在yarn-default.xml中已经有值了！
	* yarn.application.classpath对启动程序没影响，但是在运行mapreduce时影响巨大破坏力极强！
* 自定library的路径是个坑！！
	* 在windows下，执行java程序java.library.path默认到PATH路径找。这也是需要定义环境变量HADOOP_HOME，以及把bin加入到PATH的原因吧！

- - -

### 1.5 Windows直接运行cmd启动

如果是用windows的cmd的话，到这里已经基本ok了！**格式化namenode**（`hadoop namenode -format`），启动就ok了！
~~发现自己其实很傻×，固执的要用cygwin启动运行！用windows的cmd启动，然后用cygwin的终端查看数据不就行了！两不耽误！~~

cmd命令**默认**是去bin目录下找hadoop.dll的，同时hadoop命令会把bin加入到java.library.path路径下。可以直接把hadoop.dll放到bin路径（强烈推荐）。
设置环境变量，启动文件系统：

```
/* **设置环境变量** */
HADOOP_HOME=E:\local\libs\big\hadoop-2.2.0 
PATH=%HADOOP_HOME%\bin;%PATH%

/* 格式化namenode */
hadoop namenode -format

/* 操作HDFS */
set HADOOP_ROOT_LOGGER=DEBUG,console

E:\local\libs\big\hadoop-2.2.0>sbin\start-dfs.cmd

E:\local\libs\big\hadoop-2.2.0>hdfs dfs -put README.txt /   # 很弱，fs简化操作都不兼容！

E:\local\libs\big\hadoop-2.2.0>hdfs dfs -ls /
Found 1 items
-rw-r--r--   1 Administrator supergroup       1366 2014-04-22 22:20 /README.txt
```

JAVA_HOME的路径中最好不要有空格！
> instead e.g. c:\Progra~1\Java\... instead of c:\Program Files\Java\....

![](http://farm8.staticflickr.com/7460/13923348422_494288017b_o.png)

好处也是明显的，直接是windows执行，可以使用jdk自带的工具查看运行情况。

![](http://farm4.staticflickr.com/3668/13946643214_8e4666d636_o.png)

?疑问： log日志都写在hadoop.log文件中了？反正我是没看到hadoop.log的文件！

HDFS操作文件OK，如果按照上面步骤或者[官网的wiki](http://wiki.apache.org/hadoop/Hadoop2OnWindows)操作，则运行mapreduce也是不会出问题的!!

```
E:\local\libs\big\hadoop-2.2.0>sbin\start-yarn.cmd

E:\local\libs\big\hadoop-2.2.0>hadoop org.apache.hadoop.examples.WordCount /README.txt /out

E:\local\libs\big\hadoop-2.2.0>hdfs dfs -ls /out
Found 2 items
-rw-r--r--   1 Administrator supergroup          0 2014-04-22 22:22 /out/_SUCCESS
-rw-r--r--   1 Administrator supergroup       1306 2014-04-22 22:22 /out/part-r-00000
```

如果你使用上面的hadoop命令执行不了命令，请把hadoop.cmd的换行（下载下来后是unix的）转成windows的换行！

#### 问题原因分析

如果你运行mapreduce失败，不外乎三种情况：没有定义HADOOP_HOME系统环境变量，hadoop.dll没有放在PATH路径下，以及yarn.application.classpath没有设置。这三个问题导致。如果你不幸碰到了，那我们如何来确认问题呢？

下面一步步的来解读这个处理过程。在运行mapreduce时报错，可以使用远程调试方式来确认发生的具体位置。（如果你还没有弄好本地开发环境，请先看[三、导入源码到eclipse]）

第一步 调试NodeManager，从根源下手

由于windows的hadoop的程序都是**直接**运行的，不像linux还要ssh再登陆然后在启动。所以这里直接设置HADOOP_NODEMANAGER_OPTS就可以了。

```
set HADOOP_NODEMANAGER_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8092"

E:\local\libs\big\hadoop-2.2.0\sbin\start-yarn.cmd
starting yarn daemons

E:\>hadoop org.apache.hadoop.examples.WordCount /in /out
```

运行任务之前，在ContainerLaunch#call#171行打个断点（可以查看执行的java命令脚本内容，#254writeLaunchEnv写入cmd文件）。同时可以去到`nm-local-dir/nmPrivate`目录下查看任务的本地临时文件。application_XXX/containter_XXX/launch_container.cmd文件是MRAppMaster/YarnChild/YarnChild的启动脚本。

* 调试。备份生成的脚本文件，开启死循环拷贝模式，把缓存留下来慢慢看
	
	```
	while true ; do cp -rf nm-local-dir/ backup/ ; sleep 0.5; done
	```
	
	![](http://farm3.staticflickr.com/2897/13977296505_22cc6b1ca5_o.png)
		
* 查看缓存文件
	* 真正启动Mapreduce(yarnchild)的脚本文件launch_container.cmd
	* 查看系统日志，确定错误
		
		![](http://farm8.staticflickr.com/7396/13977741284_54a3abccf7_o.png)
		
	* classpath路径
		
		![](http://farm3.staticflickr.com/2904/13977751494_f5520c5899_o.png)
		
	* Job任务类型。第三个参数！
		
		![](http://farm3.staticflickr.com/2914/13977758184_bc40407385_o.png)

这里可以查看脚本，确认HADOOP的相关目录是否正确！以及查看classpath的MANIFEST.MF查看依赖的jar是否完整！也可以通过任务的名称了解相关信息。

* 路径问题，不影响大局（可以不关注/不修改）

![](http://farm4.staticflickr.com/3764/13947513865_da5c490c9e_o.png)

* 调试map/reduce

调试程序mapreduce比较好办了，毕竟代码都是自己写的好弄。可以使用mrunit。

map和reduce的进程都是动态的，既不能通过命令行的OPTS参数指定。如果要调试map/reduce需要在opts中传递给它们。

```
hadoop org.apache.hadoop.examples.WordCount  "-Dmapreduce.map.java.opts=-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8090" /in /out
```

* library问题

如果因为library的问题报access$0的错，提交任务都不成功，可以把自定义的dll路径加入java.library.path尝试一下。

```
hadoop org.apache.hadoop.examples.WordCount "-Dmapreduce.map.java.opts= -Djava.library.path=E:\local\libs\big\hadoop-2.2.0\lib\native" "-Dmapreduce.reduce.java.opts=-Djava.library.path=E:\local\libs\big\hadoop-2.2.0\lib\native"  /in /out
```

- - -

### 1.6 cygwin下运行

要在cygwin下面把hadoop弄起来，你要把cygwin与java的路径区分，理清楚路径，配置工作就成功一半咯！既然用的还是windows的java程序。配置文件也是最终提供给java执行的，所以配置都不需要修改。

要在cygwin中运行hadoop，仅仅搞定脚本就ok了！在执行java命令之前，把cygwin的路径转换为windows。

* 修改了hadoop-env.sh的内容：

```
export JAVA_HOME=/cygdrive/d/Java/jdk1.7.0_02 #本来已经在环境变量中定义了，但是执行后台批处理的时刻不会调用环境变量的配置！
export HADOOP_HEAPSIZE=512
export HADOOP_PID_DIR=${HADOOP_PID_DIR:-${HADOOP_LOG_DIR}}
```

cygwin也就是linux的默认加载native的路径是libs/native！！拷一份过去把！！或者配置JAVA_LIBRARY_PATH，参见下面的修改Shell脚本部分。

cygwin自带的工具有个优势：运行脚本和java命令都不出现乱码。（或许把SecureCRT改成GBK编码也行）

* 修改shell脚本命令

由于java在windows和linux在识别文件路径上也有差异。如/data传给java，在windows会加上当前路径的盘符(e.g. E)，那写入数据目录就为`e:/data`。

同时，不同操作系统的classpath的组织方式也不同。(1)需要对classpath已经文件夹的路径进行转换，才能在cygwin下正常的运行java程序。
所以，只要在执行java命令之前对路径和classpath进行转换即可。(2)还需要对getconf返回值的换行符进行处理。涉及到下列的文件：

```
libexec/hadoop-config.sh
bin/hadoop
bin/hdfs
bin/mapred
bin/yarn
sbin/start-dfs.sh
sbin/stop-dfs.sh
```

重点修改两个问题如下： 

* 配置

```
/* hadoop-config.sh */

# 定义时注意，处理cygwin路径时只处理了以/cygdrive开头的路径！ 
export JAVA_LIBRARY_PATH=/cygdrive/e/local/libs/big/hadoop-2.2.0/bin
```

由于windows配置时，把hadoop.dll的动态链接库放到bin目录下，而linux（cygwin）的sh脚本默认是去lib/native下面，所以需要定义一下链接库的查找路径。

* 脚本

```
/* hadoop-config.sh */

/* 在调用java命令前，调用该方法 */
function Cygwin_Patch_PathConvert() {

	cygwin=false
	case "`uname`" in
	CYGWIN*) cygwin=true;;
	esac

	# cygwin path translation
	if $cygwin; then
		CLASSPATH=`cygpath -p -w "$CLASSPATH"`
		# ssh过来执行命令是不从.bash_profile获取参数！
		if [ "X$HADOOP_HOME" != "X" ]; then
			HADOOP_HOME=`cygpath -w "$HADOOP_HOME"`
		fi
		HADOOP_LOG_DIR=`cygpath -w "$HADOOP_LOG_DIR"`
		if [ "X$TOOL_PATH" != "X" ]; then
			TOOL_PATH=`cygpath -p -w "$TOOL_PATH"`
		fi
		
HADOOP_COMMON_HOME=`cygpath -w "$HADOOP_COMMON_HOME"`
JAVA_HOME=`cygpath -w "$JAVA_HOME"`
HADOOP_YARN_HOME=`cygpath -w "$HADOOP_YARN_HOME"`
HADOOP_HDFS_HOME=`cygpath -w "$HADOOP_HDFS_HOME"`
HADOOP_CONF_DIR=`cygpath -w "$HADOOP_CONF_DIR"`

# HOME
		
		# 把带/cygdrive/[abc]形式的路径转换为windows路径
		HADOOP_OPTS=`echo $HADOOP_OPTS | awk -F" " '{for(i=1;i<=NF;i++)print $i}' | awk -F"=" ' {if($2~/^\/cygdrive\/[a|b|c|d|e]/){print $1;system("cygpath -w -p " $2 )}else{ print $0 }; print ""}' | awk 'BEGIN{opt="";last=""}{if($0~/^$/){ opt=opt " "; last="" }else{ if(last!=""){ opt=opt "="} opt=opt $0; last=$0; }; }END{ print opt }' `
		
		YARN_OPTS=`echo $YARN_OPTS | awk -F" " '{for(i=1;i<=NF;i++)print $i}' | awk -F"=" ' {if($2~/^\/cygdrive\/[a|b|c|d|e]/){print $1;system("cygpath -w -p " $2 )}else{ print $0 }; print ""}' | awk 'BEGIN{opt="";last=""}{if($0~/^$/){ opt=opt " "; last="" }else{ if(last!=""){ opt=opt "="} opt=opt $0; last=$0; }; }END{ print opt }' `

		JAVA_LIBRARY_PATH=`cygpath -p -w "$JAVA_LIBRARY_PATH"`
		
	fi
}

/* 系统的换行符不同，需要转换 */
SECONDARY_NAMENODES=$($HADOOP_PREFIX/bin/hdfs getconf -secondarynamenodes 2>/dev/null | sed 's/^M//g' )
```

在解析OPTS时执行cygpath转换的时刻，也需要加上-p的参数！OPTS中有java.library.path的环境变量！

* HDFS文件系统测试

```
bin/hadoop namenode -format
sbin/start-dfs.sh
ps
```

jps没有作用了；或者也可以通过任务管理器/**ProcessExplorer**查看java.exe，命令行列还可以查看具体的执行命令，对应的什么服务。

| 映像名称     | 用户名         | 命令行
|:-------------|:---------------|:----------------------
| java.exe     | Administrator  | D:\Java\jdk1.7.0_02\bin\java.exe -Dproc_namenode -Xmx512m ... org.apache.hadoop.hdfs.server.namenode.NameNode
| java.exe     | Administrator  | D:\Java\jdk1.7.0_02\bin\java.exe -Dproc_datanode -Xmx512m ... org.apache.hadoop.hdfs.server.datanode.DataNode
| java.exe     | Administrator  | D:\Java\jdk1.7.0_02\bin\java.exe -Dproc_secondarynamenode ... org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode

修改了hadoop的脚本，启动环境（cygwin下启动和windows启动都可以），就可以操作HDFS了。

```
Administrator@winseliu ~
$ hadoop/bin/hadoop fs -put job.xml /
14/04/22 23:53:31 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable

Administrator@winseliu ~
$ export JAVA_LIBRARY_PATH=/cygdrive/e/local/libs/big/hadoop-2.2.0/bin

Administrator@winseliu ~
$ hadoop/bin/hadoop fs -ls /
Found 4 items
-rw-r--r--   1 Administrator supergroup       1366 2014-04-22 22:20 /README.txt
-rw-r--r--   1 Administrator supergroup      66539 2014-04-22 23:53 /job.xml
drwxr-xr-x   - Administrator supergroup          0 2014-04-22 23:34 /out
drwx------   - Administrator supergroup          0 2014-04-22 22:21 /tmp
```

如果执行权限问题，可以使用设置HADOOP_USER_NAME的方式处理：

```
Administrator@winseliu ~/hadoop
$ export HADOOP_USER_NAME=Administrator

Administrator@winseliu ~/hadoop
$ bin/hadoop fs -rmr /out
```

#### MapReduce任务测试

```
sbin/start-yarn.sh
ps
```

yarn资源框架启动后，任务管理又会添加两个java的程序：

| 映像名称     | 用户名         | 命令行
|:-------------|:---------------|:---------------------
| java.exe     | Administrator  | D:\Java\jdk1.7.0_02\bin\java.exe -Dproc_resourcemanager ...  org.apache.hadoop.yarn.server.resourcemanager.ResourceManager
| java.exe     | Administrator  | D:\Java\jdk1.7.0_02\bin\java.exe -Dproc_nodemanager ... org.apache.hadoop.yarn.server.nodemanager.NodeManager

#### 提交任务，执行任务处理

在cygwin环境下，hdfs和yarn都启动成功了，并且能传文件到HDFS中。但是由于cygwin环境最终还是使用windows的java程序集群执行任务！

（可考虑[2.2 Eclipse提交MapReduce]）

* 已处理问题一： cygwin下启动nodemanager，路径没转换

由于在cygwin下面启动，大部分的环境变量都是从cygwin带过来的！解析conf中的变量时会使用nodemanager中对应变量的值，如HADOOP_MAPRED_HOME等。

在cygwin使用start-yarn.sh调用java启动程序之前需要转换路径为windows下的路径。在上面的操作已经进行了处理。

```
# 在临时目录下生成了launch_container.cmd文件，用于执行命令，而里面环境变量的值有些cygwin环境下的！

# 设置端口调试nodemanager
Administrator@winseliu ~/hadoop
$ grep "8092" etc/hadoop/*
etc/hadoop/yarn-env.sh:export YARN_NODEMANAGER_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8092"

## windows下这个方法大有文章，会把客户端传递的CLASSPATH写入jar的MANIFEST.MF中！
org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.sanitizeEnv()
```

* 已处理问题二：执行mapreduce任务时，缺少环境变量（使用Process Explorer工具查看）

```
# 设置远程调试map
hadoop org.apache.hadoop.examples.WordCount  "-Dmapreduce.map.java.opts=-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8090" /job.xml /out

# mapred-site.xml设置超时时间
	<property>
		<name>mapred.task.timeout</name>
		<value>1800000</value>
	</property>

# 结束任务
Administrator@winseliu ~/hadoop
$ bin/hadoop job -kill job_1398407971082_0003
```

* 取不到HADOOP_HOME环境变量，查找winutils.exe时报错！
	* 在hadoop-env.sh中增加定义HADOOP_HOME！
* library路径问题，解析动态链接库hadoop.dll失败！
	* 增加-D参数吧！

```
hadoop org.apache.hadoop.examples.WordCount "-Dmapreduce.map.java.opts= -Djava.library.path=E:\local\libs\big\hadoop-2.2.0\bin" "-Dmapreduce.reduce.java.opts=-Djava.library.path=E:\local\libs\big\hadoop-2.2.0\bin"  /job.xml /out
```

windows泽腾啊。

* 问题二：直接提交任务到linux集群，环境变量不匹配

```
Administrator@winseliu ~/hadoop
$ bin/hadoop  fs -ls hdfs://192.168.1.104:9000/

Administrator@winseliu ~/hadoop
$ export HADOOP_USER_NAME=hadoop

Administrator@winseliu ~/hadoop
$  bin/hadoop  org.apache.hadoop.examples.WordCount   -fs hdfs://192.168.1.104:9000 -jt 192.168.1.104 /in /out
```

由于本地是windows的java执行任务提交到集群，所以使用了`%JAVA_HOME%`，以及windows下的CLASSPATH！执行任务时，同时把nodemanager节点的临时目录备份下来再慢慢查看：

```
[hadoop@slave temp]$ while true ; do cp -rf nm-local-dir/ backup/ ; sleep 0.1; done
[hadoop@slave temp]$ find . -name "*.sh"
```

修复该问题，可以参考[2.2 Eclipse提交MapReduce]。

### 参考

[wiki-Hadoop2OnWindows]: http://wiki.apache.org/hadoop/Hadoop2OnWindows
[winutils_lnk1123_1]: http://stackoverflow.com/questions/10888391/error-link-fatal-error-lnk1123-failure-during-conversion-to-coff-file-inval
[winutils_lnk1123_2]: http://stackoverflow.com/questions/12267158/failure-during-conversion-to-coff-file-invalid-or-corrupt
[winutils_lnk1123_3]: http://social.msdn.microsoft.com/Forums/vstudio/en-US/eb4a7699-0f3c-4701-9790-199787f1b359/vs-2010-error-lnk1123-failure-during-conversion-to-coff-file-invalid-or-corrupt?forum=vcgeneral

- - - 

## 二、Windows下使用eclipse连接linux集群

### 2.1 java代码操作HDFS

```
public class HelloHdfs {

	public static boolean FINISH_CLEAN = true;

	public static void main(String[] args) throws IOException {
		System.setProperty("HADOOP_USER_NAME", "hadoop"); // 设置用户，否则会有读取权限的问题
		
		FileSystem fs = FileSystem.get(new Configuration());

		fs.mkdirs(new Path("/java/folder"));
		OutputStream os = fs.create(new Path("/java/folder/hello.txt"));
		Writer w = new BufferedWriter(new OutputStreamWriter(os, "UTF-8"));
		w.write("hello hadoop!");
		w.flush();
		w.close();
		os.close();

		FSDataInputStream is = fs.open(new Path("/java/folder/hello.txt"));
		BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));
		System.out.println(br.readLine());
		br.close();
		is.close();

		// IOUtils.copyBytes(in, out, 4096, true);

		if (FINISH_CLEAN)
			fs.delete(new Path("/java"), true);
	}

}
```

对于访问linux集群的hdfs，只要编译通过，对集群HDFS文件系统的CRUD基本没有不会遇到什么问题。写代码过程中遇到过下面两个问题：

* 如果你也引入了hive的包，可能会抛不能重写final方法的错误！由于hive中也就了proto的代码（final），调整下顺序先加载proto的包就可以了！
	
	```
	log4j:WARN Please initialize the log4j system properly.
	Exception in thread "main" java.lang.VerifyError: class org.apache.hadoop.security.proto.SecurityProtos$CancelDelegationTokenRequestProto overrides final method getUnknownFields.()Lcom/google/protobuf/UnknownFieldSet;
		at java.lang.ClassLoader.defineClass1(Native Method)
		at java.lang.ClassLoader.defineClass(ClassLoader.java:791)
	```
	
* Permission denied: user=Administrator, access=WRITE, inode="/":hadoop:supergroup:drwxr-xr-x
	这个问题的处理方式有很多。
	* hadoop fs -chmod 777 /
	* 在hdfs的配置文件中，将dfs.permissions修改为False
	* System.setProperty("user.name", "hduser")/System.setProperty("HADOOP_USER_NAME", "hduser")/configuration.set("hadoop.job.ugi", "hduser");

### 2.2 Eclipse提交MapReduce

* 需要设置HADOOP_HOME/hadoop.home.dir的环境变量，即在该目录下面有bin\winutils.exe的文件。否则会报错：
	
	```
	14/04/14 20:07:57 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
	14/04/14 20:07:58 ERROR util.Shell: Failed to locate the winutils binary in the hadoop binary path
	java.io.IOException: Could not locate executable null\bin\winutils.exe in the Hadoop binaries.
		at org.apache.hadoop.util.Shell.getQualifiedBinPath(Shell.java:278)
		at org.apache.hadoop.util.Shell.getWinUtilsPath(Shell.java:300)
		at org.apache.hadoop.util.Shell.<clinit>(Shell.java:293)
	```
	
* 任务端(map/reduce)执行命令的classpath变量在客户端Client拼装的！
	
	浏览官网的[jira](https://issues.apache.org/jira/browse/MAPREDUCE-5655 "Remote job submit from windows to a linux hadoop cluster fails due to wrong classpath")，然后下载并应用[MRApps.patch](https://issues.apache.org/jira/secure/attachment/12616981/MRApps.patch)和[YARNRunner.patch](https://issues.apache.org/jira/secure/attachment/12616982/YARNRunner.patch)两个补丁。
	
	其实就是修改Apps#addToEnvironment(Map<String, String>, String, String)来拼装特定操作系统的classpath。以及JAVA_HOME等一些环境变量的值（`$JAVA_HOME` or `%JAVA_HOME%`）
	
	使用`patch -p1 < PATCH`进行修复。如果patch文件不在项目根路径，可以删除补丁内容前面文件夹路径，直接与源文件放一起然后应用patch就行了。当然你根据修改的内容手动修改也是OK的。

如果仅仅是作为客户端client提交任务时使用。如仅在eclipse中运行main提交任务，那么就没有必要打包！直接放到需要项目源码中即可。

	* 把应用了补丁的YARNRunner和MRApps加入到项目中
	* 然后再configuration中加入`config.set("mapred.remote.os", "Linux")`
	* 把mapreduce的任务打包为jar，然后`job.setJar("helloyarn.jar")`
	* 最后`Run As -> Java Application`运行提交

如果很多项目使用，可以打包出来，然后把它添加到classpath中，同时添加加入自定义的xml配置。

```
lib-ext>jar tvf window-client-mapreduce-patch.jar
	25 Wed Apr 16 11:21:26 CST 2014 META-INF/MANIFEST.MF
 26684 Wed Apr 16 10:10:16 CST 2014 org/apache/hadoop/mapred/YARNRunner.class
 24397 Tue Apr 15 10:32:28 CST 2014 org/apache/hadoop/mapred/YARNRunner.java
  1406 Wed Apr 16 10:10:16 CST 2014 org/apache/hadoop/mapreduce/v2/util/MRApps$1.class
  2450 Wed Apr 16 10:10:16 CST 2014 org/apache/hadoop/mapreduce/v2/util/MRApps$TaskAttemptStateUI.class
 19887 Wed Apr 16 10:10:16 CST 2014 org/apache/hadoop/mapreduce/v2/util/MRApps.class
 18879 Tue Apr 15 11:42:42 CST 2014 org/apache/hadoop/mapreduce/v2/util/MRApps.java
```

![](http://farm3.staticflickr.com/2935/13958663143_a434fb0da7_o.png)

### 参考：

* [Hadoop学习三十二：Win7下无法提交MapReduce Job到集群环境](http://zy19982004.iteye.com/blog/2031172)
* [Eclipse调用hadoop2运行MR程序](http://blog.csdn.net/fansy1990/article/details/22896249)
* [jira-Remote job submit from windows to a linux hadoop cluster fails due to wrong classpath](https://issues.apache.org/jira/browse/MAPREDUCE-5655)

- - - 

## 三、导入源码到eclipse

### 环境

参考前面的【window伪分布式部署】

### 打开Visual Studio的命令行工具

```
启动\所有程序\Microsoft Visual Studio 2010\Visual Studio Tools\Visual Studio 命令提示(2010)
```

### 获取源码，检查2.2.0的分支

```
git clone git@github.com:apache/hadoop-common.git
git checkout branch-2.2.0
```

也可以下载src的源码包，但是如果想修改点东西的话，clone源码应该是最佳的选择了。

* 前面说的win32的patch，如果记得打上哦！参见[1.3 编译源代码生成本地依赖库(dll, exe)]
* 编译hadoop-auth项目的时刻报错，需要在pom中添加jetty-util的依赖，参考[找不到org.mortbay.component.AbstractLifeCycle的类文件](http://www.cnblogs.com/sysuys/p/3492791.html)。

### 编译生成打包

```
set PATH=c:\cygwin\bin;%PATH%
mvn package -Pdist,native-win -DskipTests -Dmaven.javadoc.skip=true
```

最好加上skipTests条件，不然编译等待时间不是一般的长！！

### 导入eclipse

```
mvn eclipse:eclipse
```

然后使用eclipse导入已经存在的工程(existing projects into workspace)，导入后存在两个问题：

1. stream工程的conf源码包找不到。修改为在.project文件中引用，然后把conf引用加入到.classpath。
2. common下的test代码报错。把`target/generated-test-sources/java`文件夹的也作为源码包即可。

![](http://farm8.staticflickr.com/7295/13945793574_1d5c0ea62e_o.png)

eclipse的maven插件你得安装了（要用到M2_REPO路径），同时引用正确conf\settings.xml的Maven配置路径。

注意： 不要使用eclipse导入已经存在的maven方式！eclipse的m2e有些属性和插件还不支持，导入后会报很多错！而使用`mvn eclipse:eclipse`的方式是把依赖的jar加入到`.classpath`。

### 参考

* [使用Maven将Hadoop2.2.0源码编译成Eclipse项目](http://www.cnblogs.com/zhengcong/p/3592490.html)

- - - 

## 四、胡乱噗噗

### 查看Debug日志

```
[hadoop@umcc97-44 ~]$ export HADOOP_ROOT_LOGGER=DEBUG,console
[hadoop@umcc97-44 ~]$ hadoop fs -ls /
```

### java加载动态链接库的环境变量java.library.path

```
D:\local\cygwin\Administrator\test>java LoadLib

D:\local\cygwin\Administrator\test>java -Djava.library.path=. LoadLib
Exception in thread "main" java.lang.UnsatisfiedLinkError: no hadoop in java.library.path
        at java.lang.ClassLoader.loadLibrary(ClassLoader.java:1860)
        at java.lang.Runtime.loadLibrary0(Runtime.java:845)
        at java.lang.System.loadLibrary(System.java:1084)
        at LoadLib.main(LoadLib.java:3)

D:\local\cygwin\Administrator\test>java -Djava.library.path=".;%PATH%" LoadLib

```

没有定义的时刻，会去PATH路径下找。一旦定义了java.library.path只会在给定的路径下查找！

### hadoop的本地native-library的位置

文件具体放什么位置，随便运行一个命令，通过debug的日志就可以看到默认Library的路径。

```
Administrator@winseliu ~/hadoop
$ export HADOOP_ROOT_LOGGER=DEBUG,console

Administrator@winseliu ~/hadoop
$ bin/hadoop fs -ls /

14/04/18 09:48:39 DEBUG util.NativeCodeLoader: java.library.path=E:\local\libs\big\hadoop-2.2.0\lib\native
14/04/18 09:48:39 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
```

### cygwin下运行java程序，路径问题

```
Administrator@winseliu ~/test
$ ls
ENV.class  ENV.java  w3m-0.5.2

Administrator@winseliu ~/test
$ java ENV
Windows 7

Administrator@winseliu ~/test
$ jar cvf test.jar *.class
已添加清单
正在添加: ENV.class(输入 = 475) (输出 = 307)(压缩了 35%)

Administrator@winseliu ~/test
$ ls -l
总用量 18
-rwxr-xr-x  1 Administrator None 475 四月  4 15:00 ENV.class
-rw-r--r--  1 Administrator None 117 四月  4 15:00 ENV.java
-rwxr-xr-x  1 Administrator None 758 四月 19 12:03 test.jar
drwxr-xr-x+ 1 Administrator None   0 四月 12 20:31 w3m-0.5.2

Administrator@winseliu ~/test
$ java -cp test.jar ENV
Windows 7

Administrator@winseliu ~/test
$ java -cp /home/Administrator/test/test.jar ENV
错误: 找不到或无法加载主类 ENV

Administrator@winseliu ~/test
$ set -x

Administrator@winseliu ~/test
$ java -cp `cygpath -w /home/Administrator/test/test.jar` ENV
++ cygpath -w /home/Administrator/test/test.jar
+ java -cp 'D:\local\cygwin\Administrator\test\test.jar' ENV
Windows 7
```

### [cygwin]ssh单独用户权限问题

```
Administrator@winseliu ~
$ hadoop/bin/hadoop  fs -put .bash_profile /bash.info
put: Permission denied: user=Administrator, access=WRITE, inode="/":cyg_server:supergroup:drwxr-xr-x
```

* 设置环境变量`HADOOP_USER_NAME=hadoop`
* 可以使用dfs.permissions属性设置为false。
* 给位置chown/chmod赋权: `hadoop fs -chmod 777 /`
* 也可以使用ssh-host-config的`Should privilege separation be used? (yes/no) no`设置为**no**。使用当前用户进行管理。
	```
	Administrator@winseliu /var
	$ chown Administrator:None empty/
	Administrator@winseliu ~
	$ /usr/sbin/sshd.exe # 启动，也可以弄个脚本到启动项，开机启动
	Administrator@winseliu ~/hadoop
	$ ps | grep ssh
		 4384       1    4384       4384  ?        500 02:41:21 /usr/sbin/sshd
	```

### Visual Studio处理winutils工程

* winutils的32位编译
	.net framework4, vs2010, 属性修改设置
	http://stackoverflow.com/questions/12267158/failure-during-conversion-to-coff-file-invalid-or-corrupt
	http://stackoverflow.com/questions/10888391/error-link-fatal-error-lnk1123-failure-during-conversion-to-coff-file-inval
	http://social.msdn.microsoft.com/Forums/vstudio/en-US/eb4a7699-0f3c-4701-9790-199787f1b359/vs-2010-error-lnk1123-failure-during-conversion-to-coff-file-invalid-or-corrupt?forum=vcgeneral
	
	http://hi.baidu.com/dreamthief/item/aa690d1494e2caca38cb306d
	
	在cygwin安装的时刻也看过这篇，用64位环境maven的是可以编译的
	http://www.srccodes.com/p/article/38/build-install-configure-run-apache-hadoop-2.2.0-microsoft-windows-os
	
	http://stackoverflow.com/questions/18630019/running-apache-hadoop-2-1-0-on-windows

### [cygwin]ipv6的问题，改成ipv4后不能登陆！

可能是新版本的openssh的bug！！！

```
Administrator@winseliu /cygdrive/h/documents
$ ssh -o AddressFamily=inet localhost -v
OpenSSH_6.5, OpenSSL 1.0.1g 7 Apr 2014
debug1: Reading configuration data /etc/ssh_config
debug1: Connecting to localhost [127.0.0.1] port 22.
debug1: Connection established.
debug1: identity file /home/Administrator/.ssh/id_rsa type 1
debug1: identity file /home/Administrator/.ssh/id_rsa-cert type -1
debug1: identity file /home/Administrator/.ssh/id_dsa type -1
debug1: identity file /home/Administrator/.ssh/id_dsa-cert type -1
debug1: identity file /home/Administrator/.ssh/id_ecdsa type -1
debug1: identity file /home/Administrator/.ssh/id_ecdsa-cert type -1
debug1: identity file /home/Administrator/.ssh/id_ed25519 type -1
debug1: identity file /home/Administrator/.ssh/id_ed25519-cert type -1
debug1: Enabling compatibility mode for protocol 2.0
debug1: Local version string SSH-2.0-OpenSSH_6.5
ssh_exchange_identification: read: Connection reset by peer

Administrator@winseliu ~
$ ping localhost

正在 Ping winseliu [::1] 具有 32 字节的数据:
来自 ::1 的回复: 时间<1ms
来自 ::1 的回复: 时间<1ms

```

还不能再hosts文件中加！如，指定localhost为127.0.0.1后，得到结果为：

```
Administrator@winseliu ~/hadoop
$ ssh localhost
ssh_exchange_identification: read: Connection reset by peer
```
