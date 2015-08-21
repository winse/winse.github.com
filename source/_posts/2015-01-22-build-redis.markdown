---
layout: post
title: "build redis-2.8"
date: 2015-01-22 09:59:13 +0800
comments: true
categories: [redis]
---

## jemalloc

默认make使用的libc，在内存方面会产生比较多的碎片。可以使用jemalloc要进行内存的分配管理。

如果报`make cc Command not found`，需要先安装gcc。

```
tar zxvf redis-2.8.13.bin.tar.gz 
cd redis-2.8.13
cd deps/jemalloc/
# 用于产生h头文件
./configure 

cd redis-2.8.13
make MALLOC=jemalloc
src/redis-server 
```

查看jemalloc的include的内容如下：

```
[hadoop@localhost jemalloc]$ cd include/jemalloc/
internal/              jemalloc_defs.h.in     jemalloc_macros.h      jemalloc_mangle.h      jemalloc_mangle.sh     jemalloc_protos.h.in   jemalloc_rename.h      jemalloc.sh
jemalloc_defs.h        jemalloc.h             jemalloc_macros.h.in   jemalloc_mangle_jet.h  jemalloc_protos.h      jemalloc_protos_jet.h  jemalloc_rename.sh  
```

查看内存使用：

```
[hadoop@localhost redis-2.8.13]$ src/redis-cli info
...
# Memory
used_memory:503576
used_memory_human:491.77K
used_memory_rss:2158592
used_memory_peak:503576
used_memory_peak_human:491.77K
used_memory_lua:33792
mem_fragmentation_ratio:4.29
mem_allocator:jemalloc-3.6.0
...
```

redis在使用过程中，会产生碎片。重启以及libc和jemalloc的对比如下：

```
# 运行中实例
# Memory
used_memory:4623527744
used_memory_human:4.31G
used_memory_rss:48304705536
used_memory_peak:38217543280
used_memory_peak_human:35.59G
used_memory_lua:33792
mem_fragmentation_ratio:10.45
mem_allocator:libc

51616 hadoop    20   0 45.1g  44g 1136 S  0.0 35.7   3410:42 /home/hadoop/redis-2.8.13/src/redis-server *:6371

# 序列化为rdb的文件大小
[hadoop@hadoop-master1 18111]$ ll
总用量 1183116
-rw-rw-r--. 1 hadoop hadoop 1210319541 1月  14 11:28 dump.rdb

# 重启后的实例
[hadoop@hadoop-master1 18111]$  ~/redis-2.8.13/src/redis-server --port 18111
[77484] 14 Jan 14:33:17.910 * DB loaded from disk: 218.337 seconds

# Memory
used_memory:4763158704
used_memory_human:4.44G
used_memory_rss:6217580544
used_memory_peak:4763158704
used_memory_peak_human:4.44G
used_memory_lua:33792
mem_fragmentation_ratio:1.31
mem_allocator:libc

77484 hadoop    20   0 6052m 5.8g 1200 S  0.0  4.6   3:38.39 /home/hadoop/redis-2.8.13/src/redis-server *:18111

# 使用jemalloc替换libc的实例
[hadoop@hadoop-master1 18111]$ ~/redis-jemalloc/redis-2.8.13/src/redis-server --port 18888
[14793] 14 Jan 14:50:11.250 * DB loaded from disk: 209.839 seconds

# Memory
used_memory:4527760088
used_memory_human:4.22G
used_memory_rss:4625887232
used_memory_peak:4527760088
used_memory_peak_human:4.22G
used_memory_lua:33792
mem_fragmentation_ratio:1.02
mem_allocator:jemalloc-3.6.0

14793 hadoop    20   0 4538m 4.3g 1360 S  0.0  3.4   3:28.10 /home/hadoop/redis-jemalloc/redis-2.8.13/src/redis-server *:18888                                                                                                                       
```

## tcmalloc

* root安装

如果有root用户的话操作比较简单。现在[gperftools](https://code.google.com/p/gperftools/)和[libunwind-0.99-beta](http://download.savannah.gnu.org/releases/libunwind/libunwind-0.99-beta.tar.gz)

```
cd libunwind-0.99-beta
./configure 
make && make install
cd /home/hadoop/gperftools-2.4
./configure 
make && make install

cd redis-2.8.13
make MALLOC=tcmalloc
```

如果出现**./libtool: line 1125: g++: command not found**的错误，缺少编译环境；

```
[root@localhost gperftools-2.4]# yum -y install gcc+ gcc-c++
```

编译后，运行报错**src/redis-server: error while loading shared libraries: libtcmalloc.so.4: cannot open shared object file: No such file or directory**，需要配置环境变量：

```
[hadoop@localhost redis-2.8.13]$ export LD_LIBRARY_PATH=/usr/local/lib
[hadoop@localhost redis-2.8.13]$ src/redis-server 
```

或者按照网上的做法：

```
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf  
/sbin/ldconfig  
```

检查tcmalloc是否生效`lsof -n | grep tcmalloc`，出现以下信息说明生效

```
redis-ser 1716    hadoop  mem       REG  253,0  2201976  936349 /usr/local/lib/libtcmalloc.so.4.2.6
```

修改配置文件找到daemonize，将后面的no改为yes，让其可以以服务方式运行。

* 普通用户安装

考虑到可以各台机器上面复制，指定编译目录这种方式会比较方便。

```
cd libunwind-0.99-beta
CFLAGS=-fPIC ./configure --prefix=/home/hadoop/redis
make && make install

cd gperftools-2.4
./configure -h
export LDFLAGS="-L/home/hadoop/redis/lib"
export CPPFLAGS="-I/home/hadoop/redis/include"
./configure --prefix=/home/hadoop/redis
make && make install
```

编译好后，把东西redis目录内容移到redis-2.8.13/src下。然后修改src/Makefile：

```
[hadoop@master1 redis-2.8.13]$ vi src/Makefile
# Include paths to dependencies
FINAL_CFLAGS+= -I../deps/hiredis -I../deps/linenoise -I../deps/lua/src
    
ifeq ($(MALLOC),tcmalloc)
        #FINAL_CFLAGS+= -DUSE_TCMALLOC
        #FINAL_LIBS+= -ltcmalloc
        FINAL_CFLAGS+= -DUSE_TCMALLOC -I./include
        FINAL_LIBS+= -L./lib  -ltcmalloc -ldl

endif

ifeq ($(MALLOC),tcmalloc_minimal)
        FINAL_CFLAGS+= -DUSE_TCMALLOC
        FINAL_LIBS+= -ltcmalloc_minimal
endif
```

然后编译：

```
[hadoop@master1 redis-2.8.13]$ export LD_LIBRARY_PATH=/home/hadoop/redis-2.8.13/src/lib
[hadoop@master1 redis-2.8.13]$ make MALLOC=tcmalloc
cd src && make all
make[1]: Entering directory `/home/hadoop/redis-2.8.13/src'
    LINK redis-server
    INSTALL redis-sentinel
    CC redis-cli.o
In file included from zmalloc.h:40,
                 from redis-cli.c:50:
./include/google/tcmalloc.h:35:2: warning: #warning is a GCC extension
./include/google/tcmalloc.h:35:2: warning: #warning "google/tcmalloc.h is deprecated. Use gperftools/tcmalloc.h instead"
    LINK redis-cli
    CC redis-benchmark.o
In file included from zmalloc.h:40,
                 from redis-benchmark.c:47:
./include/google/tcmalloc.h:35:2: warning: #warning is a GCC extension
./include/google/tcmalloc.h:35:2: warning: #warning "google/tcmalloc.h is deprecated. Use gperftools/tcmalloc.h instead"
    LINK redis-benchmark
    CC redis-check-dump.o
    LINK redis-check-dump
    CC redis-check-aof.o
    LINK redis-check-aof

Hint: To run 'make test' is a good idea ;)

make[1]: Leaving directory `/home/hadoop/redis-2.8.13/src'
[hadoop@master1 redis-2.8.13]$ 
```

## redis3集群安装cluster

编译安装和2.8一样，configuration/make/makeinstall即可。

```
[hadoop@umcc97-44 cluster-test]$ cat cluster.conf 
port .
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
```

比较苦逼的是需要安装ruby，服务器不能上网！其实ruby在能访问的机器上面安装就可以了！初始化集群的脚本其实就是客户端连接服务端，初始化集群而已。
还有就是在调用命令的时刻要加上`-c`，这样才是使用集群模式，不然仅仅连单机，读写其他集群服务会报错！

![](http://file.bmob.cn/M00/04/DB/wKhkA1PVx5-Ab4jaAAA9_Lg7l-I862.png)

![](http://file.bmob.cn/M00/04/DB/wKhkA1PVyXSAC5iEAABfrrHCfuI114.png)

![](http://file.bmob.cn/M00/04/DB/wKhkA1PVzBSAc3KOAADvQfFIPrs908.png)

![](http://file.bmob.cn/M00/04/DF/wKhkA1PWCc-AXZ3EAAHoKZnb1nQ426.png)

![](http://file.bmob.cn/M00/04/DF/wKhkA1PWCkWAZYuLAAAWM5VoXJI861.png)

![](http://file.bmob.cn/M00/04/DF/wKhkA1PWCuSAAuXxAABB-LpH1nQ340.png)

![](http://file.bmob.cn/M00/05/5F/wKhkA1PZBrSAPaMTAAAcSnjmhXE093.png)

## Cygwin

开发环境系统都是在windows，想调试一步步的看源码就得编译下redis。由于cygwin环境，模拟的linux，有部分的变量没有定义，需要进行修改。修改如下:

```
$ git log -1
commit 0c211a1953afeda3d0d45126653e2d4c38bd88cb
Author: antirez <antirez@gmail.com>
Date:   Fri Dec 5 10:51:09 2014 +010

$ git branch
* 2.8

$ git diff
diff --git a/deps/hiredis/net.c b/deps/hiredis/net.c
index bdb84ce..6e95f22 100644
--- a/deps/hiredis/net.c
+++ b/deps/hiredis/net.c
@@ -51,6 +51,13 @@
 #include "net.h"
 #include "sds.h"

+/* Cygwin Fix */
+#ifdef __CYGWIN__
+#define TCP_KEEPCNT 8
+#define TCP_KEEPINTVL 150
+#define TCP_KEEPIDLE 14400
+#endif
+
 /* Defined in hiredis.c */
 void __redisSetError(redisContext *c, int type, const char *str);

diff --git a/src/Makefile b/src/Makefile
index 8b3e959..a72b2f2 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -63,6 +63,9 @@ else
 ifeq ($(uname_S),Darwin)
        # Darwin (nothing to do)
 else
+ifeq ($(uname_S),CYGWIN_NT-6.3-WOW64)
+       # cygwin (nothing to do)
+else
 ifeq ($(uname_S),AIX)
         # AIX
         FINAL_LDFLAGS+= -Wl,-bexpall
@@ -75,6 +78,7 @@ else
 endif
 endif
 endif
+endif
 # Include paths to dependencies
 FINAL_CFLAGS+= -I../deps/hiredis -I../deps/linenoise -I../deps/lua/src

```
 
然后编译：

```
cd deps/
make lua hiredis linenoise

cd ..
make
``` 

编译成功后，把程序导入eclipse CDT环境进行运行调试。导入后需要重新构建一下，不然调试的时刻会按照/cygwin的路径来查找源码。

* Import，然后选择C/C++目录下的[Existing Code as Makefile project]
* 在[Existing Code Location]填入redis程序对应的目录，在[Toolchain for Indexer Settings]选择**Cygwin GCC**
* 导入完成后，右键选择[Build Configuration]->[Build All]
* Run然后选择执行redis-server即可。

好像也可以远程调试

```
[root@Frankzfz]$gdbserver 10.27.10.48:9000 ./test_seg_fault
```

## 参考

* [tcp Keepalive](http://blog.sina.com.cn/s/blog_71954d8a0100nixe.html)
* [setsockopt之 TCP_KEEPIDLE/TCP_KEEPINTVL/TCP_KEEPCNT - [Linux]](http://jiangzhixiang123.blog.163.com/blog/static/2780206220115643822896/)
* [GDB+GdbServer: ARM程序调试](http://blog.csdn.net/ce123_zhouwei/article/details/6625486)
* [使用gdbserver远程调试](http://my.oschina.net/shelllife/blog/167914)
* [用gdb,gdbserver,eclipse+cdt在windows上远程调试linux程序](http://qingfengju.com/article.asp?id=303)

* [redis源码分析（1）内存管理](http://www.cnblogs.com/kernel_hcy/archive/2011/05/15/2046963.html)
* [利用TCMalloc替换Nginx和Redis默认glibc库的malloc内存分配](http://blog.csdn.net/unix21/article/details/12119059))
* [Redis采用不同内存分配器碎片率对比](http://blog.nosqlfan.com/html/3490.html)
