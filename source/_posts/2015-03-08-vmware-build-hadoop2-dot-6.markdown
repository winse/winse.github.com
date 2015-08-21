---
layout: post
title: "VMware-Centos6 build hadoop-2.6"
date: 2015-03-08 08:22:14 +0800
comments: true
categories: [hadoop]
---

每次编译hadoop（-common）都是惊心动魄，没一次顺顺当当的！由于作者的偷懒，引发的有一起血案~~~

## 环境说明

* 操作系统

```
[root@localhost ~]# uname -a
Linux localhost.localdomain 2.6.32-431.el6.x86_64 #1 SMP Fri Nov 22 03:15:09 UTC 2013 x86_64 x86_64 x86_64 GNU/Linux
[root@localhost ~]# cat /etc/redhat-release 
CentOS release 6.5 (Final)
```

* 使用VMware的**Shared Folders**建立了maven和hadoop-2.6.0-src到宿主机器的映射：(不要直接在源码映射的目录下编译，先拷贝到linux的硬盘下！！)

```
[root@localhost ~]# ll -a hadoop-2.6.0-src maven
lrwxrwxrwx. 1 root root 26 Mar  7 22:47 hadoop-2.6.0-src -> /mnt/hgfs/hadoop-2.6.0-src
lrwxrwxrwx. 1 root root 15 Mar  7 22:47 maven -> /mnt/hgfs/maven
```

## 具体操作

```
# 安装maven，jdk
cat apache-maven-3.2.3-bin.tar.gz | ssh root@192.168.154.130 "cat - | tar zxv "

tar zxvf jdk-7u60-linux-x64.gz -C ~/
vi .bash_profile 

# 开发环境
yum install gcc glibc-headers gcc-c++ zlib-devel
yum install openssl-devel

# 安装protobuf
tar zxvf protobuf-2.5.0.tar.gz 
cd protobuf-2.5.0
./configure 
make && make install

## 编译hadoop-common
# 从映射文件中拷贝hadoop-common到linux文件系统，然后在编译hadoop-common
cd hadoop-2.6.0-src/hadoop-common-project/hadoop-common/
cd ..
cp -r  hadoop-common ~/  #Q:为啥要拷贝一份，【遇到的问题】中有进行解析
cd ~/hadoop-common
mvn install
mvn -X package -Pdist,native -Dmaven.test.skip=true -Dmaven.javadoc.skip=true

## 编译全部，耗时比较久，可以先去吃个饭^v^
cp -r /mnt/hgfs/hadoop-2.6.0-src ~/
mvn package -Pdist,native -DskipTests -Dmaven.javadoc.skip=true #Q:这里为啥不能用maven.test.skip?
```

## 遇到的问题

* 第一个问题肯定是没有**c**的编译环境，安装gcc即可。


* `configure: error: C++ preprocessor "/lib/cpp" fails sanity check`，安装c++。

-> [configure: error: C++ preprocessor "/lib/cpp" fails sanity check](http://www.cnblogs.com/niocai/archive/2011/11/04/2236458.html)


* `Unknown lifecycle phase "c"`，点击错误提示最后的链接查看解决方法，即执行`mvn install`。

-> [执行第一maven用例出错：Unknown lifecycle phase "complile".](http://blog.csdn.net/kamemo/article/details/6523992)
-> [LifecyclePhaseNotFoundException](https://cwiki.apache.org/confluence/display/MAVEN/LifecyclePhaseNotFoundException)


* `CMake Error at /usr/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:108 (message): Could NOT find ZLIB (missing: ZLIB_INCLUDE_DIR)`， 缺少zlib-devel。

-> [Cmake时报错：Could NOT find ImageMagick](http://ask.csdn.net/questions/62307)


* `cmake_symlink_library: System Error: Operation not supported`， 共享的windows目录下不能创建linux的软链接。

-> [参见9楼回复](http://bbs.chinaunix.net/forum.php?mod=viewthread&tid=3595245&fromuid=26971268)

> 创建链接不成功，要确认当前帐户下是否有权限在编译的目录中有创建链接的权限
> 
> 比如，你如果是在一个WINDOWS机器上的共享目录中编译，就没法创建链接，就会失败。把源码复制到本地的目录中再编译就不会有这问题。


* 全部编译时需使用skipTests。

```
main:
     [echo] Running test_libhdfs_threaded
     [exec] nmdCreate: NativeMiniDfsCluster#Builder#Builder error:
     [exec] java.lang.NoClassDefFoundError: org/apache/hadoop/hdfs/MiniDFSCluster$Builder
     [exec] Caused by: java.lang.ClassNotFoundException: org.apache.hadoop.hdfs.MiniDFSCluster$Builder
     [exec]     at java.net.URLClassLoader$1.run(URLClassLoader.java:366)
     [exec]     at java.net.URLClassLoader$1.run(URLClassLoader.java:355)
     [exec]     at java.security.AccessController.doPrivileged(Native Method)
     [exec]     at java.net.URLClassLoader.findClass(URLClassLoader.java:354)
     [exec]     at java.lang.ClassLoader.loadClass(ClassLoader.java:425)
     [exec]     at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:308)
     [exec]     at java.lang.ClassLoader.loadClass(ClassLoader.java:358)
     [exec] TEST_ERROR: failed on /root/hadoop-2.6.0-src/hadoop-hdfs-project/hadoop-hdfs/src/main/native/libhdfs/test_libhdfs_threaded.c:326 (errno: 2): got NULL from tlhCluster
```

* `Could NOT find OpenSSL, try to set the path to OpenSSL root folder in the`，安装openssl-devel。

```
main:
    [mkdir] Created dir: /root/hadoop-2.6.0-src/hadoop-tools/hadoop-pipes/target/native
     [exec] -- The C compiler identification is GNU 4.4.7
     [exec] -- The CXX compiler identification is GNU 4.4.7
     [exec] -- Check for working C compiler: /usr/bin/cc
     [exec] -- Check for working C compiler: /usr/bin/cc -- works
     [exec] -- Detecting C compiler ABI info
     [exec] -- Detecting C compiler ABI info - done
     [exec] -- Check for working CXX compiler: /usr/bin/c++
     [exec] -- Check for working CXX compiler: /usr/bin/c++ -- works
     [exec] -- Detecting CXX compiler ABI info
     [exec] -- Detecting CXX compiler ABI info - done
     [exec] -- Configuring incomplete, errors occurred!
     [exec] See also "/root/hadoop-2.6.0-src/hadoop-tools/hadoop-pipes/target/native/CMakeFiles/CMakeOutput.log".
     [exec] CMake Error at /usr/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:108 (message):
     [exec]   Could NOT find OpenSSL, try to set the path to OpenSSL root folder in the
     [exec]   system variable OPENSSL_ROOT_DIR (missing: OPENSSL_LIBRARIES
     [exec]   OPENSSL_INCLUDE_DIR)
     [exec] Call Stack (most recent call first):
     [exec]   /usr/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:315 (_FPHSA_FAILURE_MESSAGE)
     [exec]   /usr/share/cmake/Modules/FindOpenSSL.cmake:313 (find_package_handle_standard_args)
     [exec]   CMakeLists.txt:20 (find_package)
     [exec] 
     [exec] 
```

## 成功

```
[INFO] Executed tasks
[INFO] 
[INFO] --- maven-javadoc-plugin:2.8.1:jar (module-javadocs) @ hadoop-dist ---
[INFO] Skipping javadoc generation
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO] 
[INFO] Apache Hadoop Main ................................. SUCCESS [ 43.005 s]
[INFO] Apache Hadoop Project POM .......................... SUCCESS [ 25.511 s]
[INFO] Apache Hadoop Annotations .......................... SUCCESS [ 21.177 s]
[INFO] Apache Hadoop Assemblies ........................... SUCCESS [ 11.728 s]
[INFO] Apache Hadoop Project Dist POM ..................... SUCCESS [ 51.274 s]
[INFO] Apache Hadoop Maven Plugins ........................ SUCCESS [ 35.625 s]
[INFO] Apache Hadoop MiniKDC .............................. SUCCESS [ 21.936 s]
[INFO] Apache Hadoop Auth ................................. SUCCESS [ 24.665 s]
[INFO] Apache Hadoop Auth Examples ........................ SUCCESS [ 17.058 s]
[INFO] Apache Hadoop Common ............................... SUCCESS [06:07 min]
[INFO] Apache Hadoop NFS .................................. SUCCESS [ 41.279 s]
[INFO] Apache Hadoop KMS .................................. SUCCESS [ 59.186 s]
[INFO] Apache Hadoop Common Project ....................... SUCCESS [  7.216 s]
[INFO] Apache Hadoop HDFS ................................. SUCCESS [04:29 min]
[INFO] Apache Hadoop HttpFS ............................... SUCCESS [ 52.883 s]
[INFO] Apache Hadoop HDFS BookKeeper Journal .............. SUCCESS [ 28.972 s]
[INFO] Apache Hadoop HDFS-NFS ............................. SUCCESS [ 24.901 s]
[INFO] Apache Hadoop HDFS Project ......................... SUCCESS [  7.486 s]
[INFO] hadoop-yarn ........................................ SUCCESS [  7.466 s]
[INFO] hadoop-yarn-api .................................... SUCCESS [ 32.970 s]
[INFO] hadoop-yarn-common ................................. SUCCESS [ 25.549 s]
[INFO] hadoop-yarn-server ................................. SUCCESS [  6.709 s]
[INFO] hadoop-yarn-server-common .......................... SUCCESS [ 25.292 s]
[INFO] hadoop-yarn-server-nodemanager ..................... SUCCESS [ 29.555 s]
[INFO] hadoop-yarn-server-web-proxy ....................... SUCCESS [ 12.800 s]
[INFO] hadoop-yarn-server-applicationhistoryservice ....... SUCCESS [ 14.025 s]
[INFO] hadoop-yarn-server-resourcemanager ................. SUCCESS [ 21.121 s]
[INFO] hadoop-yarn-server-tests ........................... SUCCESS [ 24.019 s]
[INFO] hadoop-yarn-client ................................. SUCCESS [ 18.949 s]
[INFO] hadoop-yarn-applications ........................... SUCCESS [  7.586 s]
[INFO] hadoop-yarn-applications-distributedshell .......... SUCCESS [  8.428 s]
[INFO] hadoop-yarn-applications-unmanaged-am-launcher ..... SUCCESS [ 12.671 s]
[INFO] hadoop-yarn-site ................................... SUCCESS [  7.518 s]
[INFO] hadoop-yarn-registry ............................... SUCCESS [ 18.518 s]
[INFO] hadoop-yarn-project ................................ SUCCESS [ 38.781 s]
[INFO] hadoop-mapreduce-client ............................ SUCCESS [ 13.133 s]
[INFO] hadoop-mapreduce-client-core ....................... SUCCESS [ 23.772 s]
[INFO] hadoop-mapreduce-client-common ..................... SUCCESS [ 22.815 s]
[INFO] hadoop-mapreduce-client-shuffle .................... SUCCESS [ 16.810 s]
[INFO] hadoop-mapreduce-client-app ........................ SUCCESS [ 14.404 s]
[INFO] hadoop-mapreduce-client-hs ......................... SUCCESS [ 18.157 s]
[INFO] hadoop-mapreduce-client-jobclient .................. SUCCESS [ 14.637 s]
[INFO] hadoop-mapreduce-client-hs-plugins ................. SUCCESS [  9.190 s]
[INFO] Apache Hadoop MapReduce Examples ................... SUCCESS [  9.037 s]
[INFO] hadoop-mapreduce ................................... SUCCESS [ 59.280 s]
[INFO] Apache Hadoop MapReduce Streaming .................. SUCCESS [ 26.724 s]
[INFO] Apache Hadoop Distributed Copy ..................... SUCCESS [ 31.503 s]
[INFO] Apache Hadoop Archives ............................. SUCCESS [ 19.867 s]
[INFO] Apache Hadoop Rumen ................................ SUCCESS [ 27.401 s]
[INFO] Apache Hadoop Gridmix .............................. SUCCESS [ 20.102 s]
[INFO] Apache Hadoop Data Join ............................ SUCCESS [ 20.382 s]
[INFO] Apache Hadoop Ant Tasks ............................ SUCCESS [ 12.207 s]
[INFO] Apache Hadoop Extras ............................... SUCCESS [ 24.069 s]
[INFO] Apache Hadoop Pipes ................................ SUCCESS [ 31.975 s]
[INFO] Apache Hadoop OpenStack support .................... SUCCESS [ 32.225 s]
[INFO] Apache Hadoop Amazon Web Services support .......... SUCCESS [02:45 min]
[INFO] Apache Hadoop Client ............................... SUCCESS [01:38 min]
[INFO] Apache Hadoop Mini-Cluster ......................... SUCCESS [ 15.450 s]
[INFO] Apache Hadoop Scheduler Load Simulator ............. SUCCESS [ 46.489 s]
[INFO] Apache Hadoop Tools Dist ........................... SUCCESS [01:31 min]
[INFO] Apache Hadoop Tools ................................ SUCCESS [  7.603 s]
[INFO] Apache Hadoop Distribution ......................... SUCCESS [ 32.967 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 39:30 min
[INFO] Finished at: 2015-03-08T10:55:47+08:00
[INFO] Final Memory: 102M/340M
[INFO] ------------------------------------------------------------------------
```

把src编译出来的native下面的文件拷贝到hadoop集群程序目录下：

```
[hadoop@hadoop-master1 lib]$ scp -r root@172.17.42.1:~/hadoop-2.6.0-src/hadoop-dist/target/hadoop-2.6.0/lib/native ./
[hadoop@hadoop-master1 lib]$ cd native/
[hadoop@hadoop-master1 native]$ ll
total 4356
-rw-r--r--. 1 hadoop hadoop 1119518 Mar  8 03:11 libhadoop.a
-rw-r--r--. 1 hadoop hadoop 1486964 Mar  8 03:11 libhadooppipes.a
lrwxrwxrwx. 1 hadoop hadoop      18 Mar  3 21:08 libhadoop.so -> libhadoop.so.1.0.0
-rwxr-xr-x. 1 hadoop hadoop  671237 Mar  8 03:11 libhadoop.so.1.0.0
-rw-r--r--. 1 hadoop hadoop  581944 Mar  8 03:11 libhadooputils.a
-rw-r--r--. 1 hadoop hadoop  359490 Mar  8 03:11 libhdfs.a
lrwxrwxrwx. 1 hadoop hadoop      16 Mar  3 21:08 libhdfs.so -> libhdfs.so.0.0.0
-rwxr-xr-x. 1 hadoop hadoop  228451 Mar  8 03:11 libhdfs.so.0.0.0
```

添加编译的native包前后对比：

```
[hadoop@hadoop-master1 hadoop-2.6.0]$ hadoop fs -ls /
15/03/08 03:09:12 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Found 3 items
-rw-r--r--   1 hadoop supergroup       1366 2015-03-06 16:49 /README.txt
drwx------   - hadoop supergroup          0 2015-03-06 16:54 /tmp
drwxr-xr-x   - hadoop supergroup          0 2015-03-06 16:54 /user
[hadoop@hadoop-master1 hadoop-2.6.0]$ hadoop fs -ls /
Found 3 items
-rw-r--r--   1 hadoop supergroup       1366 2015-03-06 16:49 /README.txt
drwx------   - hadoop supergroup          0 2015-03-06 16:54 /tmp
drwxr-xr-x   - hadoop supergroup          0 2015-03-06 16:54 /user
```
