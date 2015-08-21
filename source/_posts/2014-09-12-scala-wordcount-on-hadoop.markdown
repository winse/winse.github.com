---
layout: post
title: "scala wordcount on hadoop2"
date: 2014-09-12 07:52:01 +0800
comments: true
categories: [hadoop, scala]
---

从了解scala，到spark再次遇见scala，准备好好学学这门语言。函数式编程大势所趋，简洁的语法，更抽象好用的集合操作。土生土长的JVM的语言，以及凭借其与java的互操作性，发展前景一片光明。在云计算以及手机（android）开发都有其大展拳脚的地方。

工作中大部分时间写mapreduce，项目空白期实践了一下把scala搬上hadoop。整体来说用scala写个helloworld是比较简单的，就一些细节的东西比较繁琐。尽管用了几年的eclipse了，但是[scala-ide](http://scala-ide.org/)还是需要再适应适应！scala-idea也没有大家说的那么好，和webstorm比差远了。

{% gist winse/5df39f77e8bd59348a7a %}

使用scala主要原因：

* 写JavaBean更简单方便
* 多返回值无需定义Result实体类
* 集合更抽象的方法真的很好用
* trait可以更便捷的进行操作层面的聚合，也就是可以把操作分离出来，进行组合就可以实现新的功能。这不就是decorate模式嘛！java的decorate多麻烦的！加点东西太麻烦了！！！

上面的scala代码和java的比较类似，主要在集合操作上不同而已，变量定义简单化。

编写好代码后就是运行调试。

前面其他的文章已经说过了，默认`mapreduce.framework.name`的配置是本地`local`，所以直接运行就像运行一个普通的本地java程序。这就不多讲了。
这里主要讲讲怎么把代码打包放到真实的集群环境运行，相比java的版本要添加那些步骤。

从项目的maven pom中可以发现，其实就是多了`scala-lang`的新**依赖**而已，其他都是hadoop自带的公共包。

![](http://file.bmob.cn/M00/0E/A2/wKhkA1QUHV6AAJoCAABANktCWmk664.png)

所以运行程序只需要指定把scala-lang.jar添加到运行环境的classpath中即可。使用maven打包后的项目结构如下：

```
[hadoop@master1 scalamapred-1.0.5]$ cd lib/
[hadoop@master1 lib]$ ls -l
total 8
drwxrwxr-x. 2 hadoop hadoop 4096 Sep 11 23:10 common
drwxrwxr-x. 2 hadoop hadoop 4096 Sep 11 23:56 core
[hadoop@master1 lib]$ ll core/
total 12
-rw-r--r--. 1 hadoop hadoop 11903 Sep 11 23:55 scalamapred-1.0.5.jar
[hadoop@master1 lib]$ ls common/
activation-1.1.jar                commons-lang-2.6.jar            hadoop-hdfs-2.2.0.jar                     jaxb-api-2.2.2.jar                      log4j-1.2.17.jar
aopalliance-1.0.jar               commons-logging-1.1.1.jar       hadoop-mapreduce-client-common-2.2.0.jar  jaxb-impl-2.2.3-1.jar                   management-api-3.0.0-b012.jar
asm-3.1.jar                       commons-math-2.1.jar            hadoop-mapreduce-client-core-2.2.0.jar    jersey-client-1.9.jar                   netty-3.6.2.Final.jar
avro-1.7.4.jar                    commons-net-3.1.jar             hadoop-yarn-api-2.2.0.jar                 jersey-core-1.9.jar                     paranamer-2.3.jar
commons-beanutils-1.7.0.jar       gmbal-api-only-3.0.0-b023.jar   hadoop-yarn-client-2.2.0.jar              jersey-grizzly2-1.9.jar                 protobuf-java-2.5.0.jar
commons-beanutils-core-1.8.0.jar  grizzly-framework-2.1.2.jar     hadoop-yarn-common-2.2.0.jar              jersey-guice-1.9.jar                    scala-library-2.10.4.jar
commons-cli-1.2.jar               grizzly-http-2.1.2.jar          hadoop-yarn-server-common-2.2.0.jar       jersey-json-1.9.jar                     servlet-api-2.5.jar
commons-codec-1.4.jar             grizzly-http-server-2.1.2.jar   jackson-core-asl-1.8.8.jar                jersey-server-1.9.jar                   slf4j-api-1.7.1.jar
commons-collections-3.2.1.jar     grizzly-http-servlet-2.1.2.jar  jackson-jaxrs-1.8.3.jar                   jersey-test-framework-core-1.9.jar      slf4j-log4j12-1.7.1.jar
commons-compress-1.4.1.jar        grizzly-rcm-2.1.2.jar           jackson-mapper-asl-1.8.8.jar              jersey-test-framework-grizzly2-1.9.jar  snappy-java-1.0.4.1.jar
commons-configuration-1.6.jar     guava-17.0.jar                  jackson-xc-1.8.3.jar                      jets3t-0.6.1.jar                        stax-api-1.0.1.jar
commons-daemon-1.0.13.jar         guice-3.0.jar                   jasper-compiler-5.5.23.jar                jettison-1.1.jar                        xmlenc-0.52.jar
commons-digester-1.8.jar          guice-servlet-3.0.jar           jasper-runtime-5.5.23.jar                 jetty-6.1.26.jar                        xz-1.0.jar
commons-el-1.0.jar                hadoop-annotations-2.2.0.jar    javax.inject-1.jar                        jetty-util-6.1.26.jar                   zookeeper-3.4.5.jar
commons-httpclient-3.1.jar        hadoop-auth-2.2.0.jar           javax.servlet-3.1.jar                     jsch-0.1.42.jar
commons-io-2.1.jar                hadoop-common-2.2.0.jar         javax.servlet-api-3.0.1.jar               jsp-api-2.1.jar
[hadoop@master1 lib]$ 
```

完整的pom.xml的内容为：

```
	<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
		<modelVersion>4.0.0</modelVersion>

		<groupId>com.winse</groupId>
		<version>1.0</version>

		<artifactId>scalamapred</artifactId>

		<build>
			<plugins>
				<plugin>
					<groupId>org.scala-tools</groupId>
					<artifactId>maven-scala-plugin</artifactId>
					<version>2.15.2</version>
					<executions>
						<execution>
							<id>scala-compile-first</id>
							<phase>process-resources</phase>
							<goals>
								<goal>add-source</goal>
								<goal>compile</goal>
							</goals>
						</execution>
						<execution>
							<id>scala-test-compile</id>
							<phase>process-test-resources</phase>
							<goals>
								<goal>testCompile</goal>
							</goals>
						</execution>
					</executions>
					<configuration>
						<scalaVersion>${scala.version}</scalaVersion>
					</configuration>
				</plugin>

				<plugin>
					<groupId>org.codehaus.mojo</groupId>
					<artifactId>build-helper-maven-plugin</artifactId>
					<version>1.8</version>
					<executions>
						<execution>
							<id>add-scala-sources</id>
							<phase>generate-sources</phase>
							<goals>
								<goal>add-source</goal>
							</goals>
							<configuration>
								<sources>
									<source>${basedir}/src/main/scala</source>
								</sources>
							</configuration>
						</execution>
						<execution>
							<id>add-scala-test-sources</id>
							<phase>generate-test-sources</phase>
							<goals>
								<goal>add-test-source</goal>
							</goals>
							<configuration>
								<sources>
									<source>${basedir}/src/test/scala</source>
								</sources>
							</configuration>
						</execution>
					</executions>
				</plugin>
			</plugins>
		</build>

		<dependencies>
			<dependency>
				<groupId>org.apache.hadoop</groupId>
				<artifactId>hadoop-mapreduce-client-common</artifactId>
				<version>${hadoop.version}</version>
			</dependency>
			<dependency>
				<groupId>org.apache.hadoop</groupId>
				<artifactId>hadoop-hdfs</artifactId>
				<version>${hadoop.version}</version>
			</dependency>
			<dependency>
				<groupId>org.apache.hadoop</groupId>
				<artifactId>hadoop-mapreduce-client-core</artifactId>
				<version>${hadoop.version}</version>
			</dependency>
			<dependency>
				<groupId>org.apache.hadoop</groupId>
				<artifactId>hadoop-common</artifactId>
				<version>${hadoop.version}</version>
			</dependency>
			<dependency>
				<groupId>org.scala-lang</groupId>
				<artifactId>scala-library</artifactId>
				<version>${scala.version}</version>
			</dependency>
		</dependencies>
		<properties>
			<scala.version>2.10.4</scala.version>
			<hadoop.version>2.2.0</hadoop.version>
		</properties>

		<profiles>
			<profile>
				<id>tar</id>
				<build>
					<plugins>
						<plugin>
							<groupId>org.apache.maven.plugins</groupId>
							<artifactId>maven-assembly-plugin</artifactId>
							<executions>
								<execution>
									<id>make-assembly</id>
									<phase>package</phase>
									<goals>
										<goal>single</goal>
									</goals>
								</execution>
							</executions>
						</plugin>

					</plugins>
				</build>
			</profile>
		</profiles>

		<repositories>
			<repository>
				<id>scala-tools.org</id>
				<name>Scala-tools Maven2 Repository</name>
				<url>http://scala-tools.org/repo-releases</url>
			</repository>
		</repositories>
		<pluginRepositories>
			<pluginRepository>
				<id>scala-tools.org</id>
				<name>Scala-tools Maven2 Repository</name>
				<url>http://scala-tools.org/repo-releases</url>
			</pluginRepository>
		</pluginRepositories>

	</project>
```

在lib文件夹下面包括common和core两放置jar的文件夹，common是项目的依赖包，core下面的是项目的源码jar。

接下来运行程序，通过libjar把**scala-library的包加入到mapreduce的运行时classpath**。当然也可以把scala-library加入到`mapreduce.application.classpath`（默认值为`$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*`）。

```
[hadoop@master1 scalamapred-1.0.5]$ for j in `find . -name "*.jar"` ; do export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$j ; done
[hadoop@master1 scalamapred-1.0.5]$ 
[hadoop@master1 scalamapred-1.0.5]$ export HADOOP_CLASSPATH=
[hadoop@master1 scalamapred-1.0.5]$ export HADOOP_CLASSPATH=/home/hadoop/scalamapred-1.0.5/lib/core/*:/home/hadoop/scalamapred-1.0.5/lib/common/*
[hadoop@master1 scalamapred-1.0.5]$ hadoop com.github.winse.hadoop.HelloScalaMapRed -libjars lib/common/scala-library-2.10.4.jar 
```

## 问题攻略

上面如果不加libjar的话，会在nodemanager的代码中抛出异常。本来认为不加依赖包也就不能执行mapreduce里面的代码而已。问题的根源在哪里呢？

给代码添加远程调试的配置，然后运行一步步的查找问题（一次找不到就多运行调试几次）。

```
[hadoop@master1 scalamapred-1.0.5]$ hadoop com.github.winse.hadoop.HelloScalaMapRed  -Dyarn.app.mapreduce.am.command-opts="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090"

// 我这里slaver就一台，取到机器上查看运行的程序

[hadoop@slaver1 nmPrivate]$ ps axu|grep java
hadoop    1427  0.6 10.5 1562760 106344 ?      Sl   Sep11   0:45 /opt/jdk1.7.0_60//bin/java -Dproc_datanode -Xmx1000m -Djava.net.preferIPv4Stack=true -Dhadoop.log.dir=/home/hadoop/hadoop-2.2.0/logs -Dhadoop.log.file=hadoop.log -Dhadoop.home.dir=/home/hadoop/hadoop-2.2.0 -Dhadoop.id.str=hadoop -Dhadoop.root.logger=INFO,console -Djava.library.path=/home/hadoop/hadoop-2.2.0/lib/native -Dhadoop.policy.file=hadoop-policy.xml -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv4Stack=true -Dhadoop.log.dir=/home/hadoop/hadoop-2.2.0/logs -Dhadoop.log.file=hadoop-hadoop-datanode-slaver1.log -Dhadoop.home.dir=/home/hadoop/hadoop-2.2.0 -Dhadoop.id.str=hadoop -Dhadoop.root.logger=INFO,RFA -Djava.library.path=/home/hadoop/hadoop-2.2.0/lib/native -Dhadoop.policy.file=hadoop-policy.xml -Djava.net.preferIPv4Stack=true -server -Dhadoop.security.logger=ERROR,RFAS -Dhadoop.security.logger=ERROR,RFAS -Dhadoop.security.logger=ERROR,RFAS -Dhadoop.security.logger=INFO,RFAS org.apache.hadoop.hdfs.server.datanode.DataNode
hadoop    2874  2.5 11.7 1599312 118980 ?      Sl   00:08   0:57 /opt/jdk1.7.0_60//bin/java -Dproc_nodemanager -Xmx1000m -Dhadoop.log.dir=/home/hadoop/hadoop-2.2.0/logs -Dyarn.log.dir=/home/hadoop/hadoop-2.2.0/logs -Dhadoop.log.file=yarn-hadoop-nodemanager-slaver1.log -Dyarn.log.file=yarn-hadoop-nodemanager-slaver1.log -Dyarn.home.dir= -Dyarn.id.str=hadoop -Dhadoop.root.logger=INFO,RFA -Dyarn.root.logger=INFO,RFA -Djava.library.path=/home/hadoop/hadoop-2.2.0/lib/native -Dyarn.policy.file=hadoop-policy.xml -server -Dhadoop.log.dir=/home/hadoop/hadoop-2.2.0/logs -Dyarn.log.dir=/home/hadoop/hadoop-2.2.0/logs -Dhadoop.log.file=yarn-hadoop-nodemanager-slaver1.log -Dyarn.log.file=yarn-hadoop-nodemanager-slaver1.log -Dyarn.home.dir=/home/hadoop/hadoop-2.2.0 -Dhadoop.home.dir=/home/hadoop/hadoop-2.2.0 -Dhadoop.root.logger=INFO,RFA -Dyarn.root.logger=INFO,RFA -Djava.library.path=/home/hadoop/hadoop-2.2.0/lib/native -classpath /home/hadoop/hadoop-2.2.0/etc/hadoop:/home/hadoop/hadoop-2.2.0/etc/hadoop:/home/hadoop/hadoop-2.2.0/etc/hadoop:/home/hadoop/hadoop-2.2.0/share/hadoop/common/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/common/*:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/hdfs/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/*:/home/hadoop/hadoop-2.2.0/share/hadoop/mapreduce/lib/*:/home/hadoop/hadoop-2.2.0/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar:/contrib/capacity-scheduler/*.jar:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/*:/home/hadoop/hadoop-2.2.0/share/hadoop/yarn/lib/*:/home/hadoop/hadoop-2.2.0/etc/hadoop/nm-config/log4j.properties org.apache.hadoop.yarn.server.nodemanager.NodeManager
hadoop    3750  0.0  0.1 106104  1200 ?        Ss   00:43   0:00 /bin/bash -c /opt/jdk1.7.0_60//bin/java -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA  -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090 org.apache.hadoop.mapreduce.v2.app.MRAppMaster 1>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001/stdout 2>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001/stderr 
hadoop    3759  0.1  1.8 737648 18232 ?        Sl   00:43   0:00 /opt/jdk1.7.0_60//bin/java -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090 org.apache.hadoop.mapreduce.v2.app.MRAppMaster
hadoop    3778  0.0  0.0 103256   832 pts/0    S+   00:45   0:00 grep java

// 取到对应的目录下查看launcher.sh的脚本
// appmaster launcher

[hadoop@slaver1 nm-local-dir]$ cd nmPrivate/application_1410453720744_0007/
[hadoop@slaver1 application_1410453720744_0007]$ ll
total 4
drwxrwxr-x. 2 hadoop hadoop 4096 Sep 12 00:43 container_1410453720744_0007_01_000001
[hadoop@slaver1 application_1410453720744_0007]$ less container_1410453720744_0007_01_000001/
container_1410453720744_0007_01_000001.tokens       launch_container.sh                                 
.container_1410453720744_0007_01_000001.tokens.crc  .launch_container.sh.crc                            
[hadoop@slaver1 application_1410453720744_0007]$ less container_1410453720744_0007_01_000001/launch_container.sh 
#!/bin/bash

export NM_HTTP_PORT="8042"
export LOCAL_DIRS="/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007"
export HADOOP_COMMON_HOME="/home/hadoop/hadoop-2.2.0"
export JAVA_HOME="/opt/jdk1.7.0_60/"
export NM_AUX_SERVICE_mapreduce_shuffle="AAA0+gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
"
export HADOOP_YARN_HOME="/home/hadoop/hadoop-2.2.0"
export CLASSPATH="$PWD:$HADOOP_CONF_DIR:$HADOOP_COMMON_HOME/share/hadoop/common/*:$HADOOP_COMMON_HOME/share/hadoop/common/lib/*:$HADOOP_HDFS_HOME/share/hadoop/hdfs/*:$HADOOP_HDFS_HOME/share/hadoop/hdfs/lib/*:$HADOOP_YARN_HOME/share/hadoop/yarn/*:$HADOOP_YARN_HOME/share/hadoop/yarn/lib/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*:job.jar/job.jar:job.jar/classes/:job.jar/lib/*:$PWD/*"
export HADOOP_TOKEN_FILE_LOCATION="/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/container_1410453720744_0007_01_000001/container_tokens"
export NM_HOST="slaver1"
export APPLICATION_WEB_PROXY_BASE="/proxy/application_1410453720744_0007"
export JVM_PID="$$"
export USER="hadoop"
export HADOOP_HDFS_HOME="/home/hadoop/hadoop-2.2.0"
export PWD="/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/container_1410453720744_0007_01_000001"
export CONTAINER_ID="container_1410453720744_0007_01_000001"
export HOME="/home/"
export NM_PORT="40888"
export LOGNAME="hadoop"
export APP_SUBMIT_TIME_ENV="1410455811401"
export MAX_APP_ATTEMPTS="2"
export HADOOP_CONF_DIR="/home/hadoop/hadoop-2.2.0/etc/hadoop"
export MALLOC_ARENA_MAX="4"
export LOG_DIRS="/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001"
ln -sf "/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/filecache/10/job.jar" "job.jar"
ln -sf "/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/filecache/13/job.xml" "job.xml"
mkdir -p jobSubmitDir
ln -sf "/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/filecache/11/job.splitmetainfo" "jobSubmitDir/job.splitmetainfo"
mkdir -p jobSubmitDir
ln -sf "/home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/filecache/12/job.split" "jobSubmitDir/job.split"
exec /bin/bash -c "$JAVA_HOME/bin/java -Dlog4j.configuration=container-log4j.properties -Dyarn.app.container.log.dir=/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001 -Dyarn.app.container.log.filesize=0 -Dhadoop.root.logger=INFO,CLA  -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090 org.apache.hadoop.mapreduce.v2.app.MRAppMaster 1>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001/stdout 2>/home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410453720744_0007/container_1410453720744_0007_01_000001/stderr "

// 去到TMP对应的目录下，查看整个运行的根目录

[hadoop@slaver1 ~]$ cd /home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/container_1410453720744_0007_01_000001
[hadoop@slaver1 container_1410453720744_0007_01_000001]$ ll
total 28
-rw-r--r--. 1 hadoop hadoop   95 Sep 12 00:43 container_tokens
-rwx------. 1 hadoop hadoop  468 Sep 12 00:43 default_container_executor.sh
lrwxrwxrwx. 1 hadoop hadoop  108 Sep 12 00:43 job.jar -> /home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/filecache/10/job.jar
drwxrwxr-x. 2 hadoop hadoop 4096 Sep 12 00:43 jobSubmitDir
lrwxrwxrwx. 1 hadoop hadoop  108 Sep 12 00:43 job.xml -> /home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0007/filecache/13/job.xml
-rwx------. 1 hadoop hadoop 3005 Sep 12 00:43 launch_container.sh
drwx--x---. 2 hadoop hadoop 4096 Sep 12 00:43 tmp
[hadoop@slaver1 container_1410453720744_0007_01_000001]$ 

```

为了对应，我这里列出来在添加了libjar的TMP目录的列表：

```
[hadoop@master1 scalamapred-1.0.5]$ hadoop com.github.winse.hadoop.HelloScalaMapRed  -Dyarn.app.mapreduce.am.command-opts="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090" -libjars lib/common/scala-library-2.10.4.jar 

[hadoop@slaver1 container_1410453720744_0007_01_000001]$ cd /home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0008/container_1410453720744_0008_01_000001
[hadoop@slaver1 container_1410453720744_0008_01_000001]$ ll
total 32
-rw-r--r--. 1 hadoop hadoop   95 Sep 12 00:49 container_tokens
-rwx------. 1 hadoop hadoop  468 Sep 12 00:49 default_container_executor.sh
lrwxrwxrwx. 1 hadoop hadoop  108 Sep 12 00:49 job.jar -> /home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0008/filecache/10/job.jar
drwxrwxr-x. 2 hadoop hadoop 4096 Sep 12 00:49 jobSubmitDir
lrwxrwxrwx. 1 hadoop hadoop  108 Sep 12 00:49 job.xml -> /home/hadoop/data/nm-local-dir/usercache/hadoop/appcache/application_1410453720744_0008/filecache/13/job.xml
-rwx------. 1 hadoop hadoop 3127 Sep 12 00:49 launch_container.sh
lrwxrwxrwx. 1 hadoop hadoop   85 Sep 12 00:49 scala-library-2.10.4.jar -> /home/hadoop/data/nm-local-dir/usercache/hadoop/filecache/10/scala-library-2.10.4.jar
drwx--x---. 2 hadoop hadoop 4096 Sep 12 00:49 tmp
[hadoop@slaver1 container_1410453720744_0008_01_000001]$ 
```

windows本地使用eclipse和进行跟踪调试代码。

![](http://file.bmob.cn/M00/0E/A1/wKhkA1QUG0aARyPVAAMnUXGDgbY378.png)

此时可以通过8088的网页查看状态，当前有一个mrappmaster在执行，如果第一个失败，会尝试执行第二次。

![](http://file.bmob.cn/M00/0E/A2/wKhkA1QUHDGAe0anAAEfiNTmB1k734.png)

运行调试多次后，**最终确定问题**所在。在master中会检查是否为链式mr，而加载该class的时刻，同时要加载父类的class，即scala的类，所以在这里会抛出异常。

![](http://file.bmob.cn/M00/0E/A2/wKhkA1QUHFOAWJulAAPOawkAbgo349.png)

去到查看程序运行的日志，可以看到程序抛出的异常**NoClassDefFoundError**。

```
[hadoop@slaver1 ~]$ less /home/hadoop/hadoop-2.2.0/logs/userlogs/application_1410448728371_0003/*/syslog
2014-09-11 22:55:12,616 INFO [main] org.apache.hadoop.mapreduce.v2.app.MRAppMaster: Created MRAppMaster for application appattempt_1410448728371_0003_000001
...
2014-09-11 22:55:18,677 INFO [main] org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl: Adding job token for job_1410448728371_0003 to jobTokenSecretManager
2014-09-11 22:55:19,119 FATAL [main] org.apache.hadoop.mapreduce.v2.app.MRAppMaster: Error starting MRAppMaster
java.lang.NoClassDefFoundError: scala/Function1
        at java.lang.Class.forName0(Native Method)
        at java.lang.Class.forName(Class.java:190)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl.isChainJob(JobImpl.java:1277)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl.makeUberDecision(JobImpl.java:1217)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl.access$3700(JobImpl.java:135)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl$InitTransition.transition(JobImpl.java:1420)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl$InitTransition.transition(JobImpl.java:1358)
        at org.apache.hadoop.yarn.state.StateMachineFactory$MultipleInternalArc.doTransition(StateMachineFactory.java:385)
        at org.apache.hadoop.yarn.state.StateMachineFactory.doTransition(StateMachineFactory.java:302)
        at org.apache.hadoop.yarn.state.StateMachineFactory.access$300(StateMachineFactory.java:46)
        at org.apache.hadoop.yarn.state.StateMachineFactory$InternalStateMachine.doTransition(StateMachineFactory.java:448)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl.handle(JobImpl.java:972)
        at org.apache.hadoop.mapreduce.v2.app.job.impl.JobImpl.handle(JobImpl.java:134)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster$JobEventDispatcher.handle(MRAppMaster.java:1227)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster.serviceStart(MRAppMaster.java:1035)
        at org.apache.hadoop.service.AbstractService.start(AbstractService.java:193)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster$1.run(MRAppMaster.java:1445)
        at java.security.AccessController.doPrivileged(Native Method)
        at javax.security.auth.Subject.doAs(Subject.java:415)
        at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1491)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster.initAndStartAppMaster(MRAppMaster.java:1441)
        at org.apache.hadoop.mapreduce.v2.app.MRAppMaster.main(MRAppMaster.java:1374)
Caused by: java.lang.ClassNotFoundException: scala.Function1
        at java.net.URLClassLoader$1.run(URLClassLoader.java:366)
        at java.net.URLClassLoader$1.run(URLClassLoader.java:355)
        at java.security.AccessController.doPrivileged(Native Method)
        at java.net.URLClassLoader.findClass(URLClassLoader.java:354)
        at java.lang.ClassLoader.loadClass(ClassLoader.java:425)
        at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:308)
        at java.lang.ClassLoader.loadClass(ClassLoader.java:358)
        ... 22 more
2014-09-11 22:55:19,130 INFO [Thread-1] org.apache.hadoop.mapreduce.v2.app.MRAppMaster: MRAppMaster received a signal. Signaling RMCommunicator and JobHistoryEventHandler.
```

## 意外收获

* 推测执行初始化代码

![](http://file.bmob.cn/M00/0E/A2/wKhkA1QUHHCATFHtAAMeDcCHWzU166.png)

* OutputFormat的获取Committer代码

![](http://file.bmob.cn/M00/0E/A2/wKhkA1QUHImAJAq1AALGEfA-F9k811.png)

## 参考

* [Hadoop with Scala: hacking notes](http://digifesto.com/2013/04/15/hadoop-with-scala-hacking-notes/)
* [ScalaOnHadoop WordCount.scala](https://github.com/derrickcheng/ScalaOnHadoop/blob/master/src/main/scala/WordCount.scala)
