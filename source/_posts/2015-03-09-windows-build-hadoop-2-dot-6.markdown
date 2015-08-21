---
layout: post
title: "Windows build hadoop-2.6"
date: 2015-03-09 12:01:55 +0800
comments: true
categories: [hadoop]
---

## 环境

```
C:\Users\winse>java -version
java version "1.7.0_02"
Java(TM) SE Runtime Environment (build 1.7.0_02-b13)
Java HotSpot(TM) Client VM (build 22.0-b10, mixed mode, sharing)

C:\Users\winse>protoc --version
libprotoc 2.5.0

winse@Lenovo-PC ~
$ cygcheck -c cygwin
Cygwin Package Information
Package              Version        Status
cygwin               1.7.33-1       OK
```

## 具体步骤

在windows下，hadoop-2.6还不能直接编译java-x86的dll。需要自己处理/打patch[HADOOP-9922](https://issues.apache.org/jira/browse/HADOOP-9922)，但是官网jira-patch给出来的和2.6.0-src对不上。自己动手丰衣足食，把x64的全部改成Win32即可，附编译成功的patch[下载hadoop-2.6.0-common-native-win32-diff.patch（提取码：08fd）](http://yunpan.cn/cJaZzSu6DIibg)。

* 用visual studio2010的x86命令行进入：

```
Visual Studio 命令提示(2010)

Setting environment for using Microsoft Visual Studio 2010 x86 tools.
```

* 切换到hadoop源码目录，打补丁和编译。同时protobuf目录和cygwin\bin目录加入PATH：

```
cd hadoop-2.6.0-src
cd hadoop-common-project\hadoop-common
patch -p0 < hadoop-2.6.0-common-native-win32-diff.patch

set PATH=%PATH%;E:\local\home\Administrator\bin;c:\cygwin\bin

mvn package -Pdist,native-win -DskipTests -Dtar -Dmaven.javadoc.skip=true
```

* 编译完成后，直接把`hadoop-common\target\bin`目录下的内容拷贝到程序的bin目录下。

在windows下，执行java程序java.library.path默认到PATH路径找。这也是需要定义**环境变量HADOOP_HOME**，以及把`%HADOOP_HOME%\bin`加入到PATH的原因！

```
HADOOP_HOME=E:\local\libs\big\hadoop-2.2.0 
PATH=%HADOOP_HOME%\bin;%PATH%
```

* 配置坑：

```
winse@Lenovo-PC /cygdrive/e/local/opt/bigdata/hadoop-2.6.0
$ find . -name "*-default.xml" | xargs -I{} grep "hadoop.tmp.dir" {}
  <value>${hadoop.tmp.dir}/mapred/local</value>
  <value>${hadoop.tmp.dir}/mapred/system</value>
  <value>${hadoop.tmp.dir}/mapred/staging</value>
  <value>${hadoop.tmp.dir}/mapred/temp</value>
  <value>${hadoop.tmp.dir}/mapred/history/recoverystore</value>
  <name>hadoop.tmp.dir</name>
  <value>${hadoop.tmp.dir}/io/local</value>
  <value>${hadoop.tmp.dir}/s3</value>
  <value>${hadoop.tmp.dir}/s3a</value>
  <value>file://${hadoop.tmp.dir}/dfs/name</value>
  <value>file://${hadoop.tmp.dir}/dfs/data</value>
  <value>file://${hadoop.tmp.dir}/dfs/namesecondary</value>
    <value>${hadoop.tmp.dir}/yarn/system/rmstore</value>
    <value>${hadoop.tmp.dir}/nm-local-dir</value>
    <value>${hadoop.tmp.dir}/yarn-nm-recovery</value>
    <value>${hadoop.tmp.dir}/yarn/timeline</value>
```

就dfs的在前面加了`file://`前缀！

所以，在windows下如果你只配置hadoop.tmp.dir（`file:///e:/tmp/hadoop`）的话还得同时配置：

```
<property>
  <name>dfs.namenode.name.dir</name>
  <value>${hadoop.tmp.dir}/dfs/name</value>
</property>

<property>
  <name>dfs.datanode.data.dir</name>
  <value>${hadoop.tmp.dir}/dfs/data</value>
</property>

<property>
  <name>dfs.namenode.checkpoint.dir</name>
  <value>${hadoop.tmp.dir}/dfs/namesecondary</value>
</property>
```

接下来格式化，启动都和同时一样。

## 其他

调试，下载maven源码等

```
set HADOOP_NAMENODE_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8090"

mvn dependency:resolve -Dclassifier=sources

mvn eclipse:eclipse -DdownloadSources -DdownloadJavadocs 

mvn dependency:sources 
mvn dependency:resolve -Dclassifier=javadoc

/* 操作HDFS */
set HADOOP_ROOT_LOGGER=DEBUG,console
```

