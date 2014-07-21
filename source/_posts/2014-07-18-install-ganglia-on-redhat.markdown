---
layout: post
title: "[笔记] install ganglia on Redhat5+"
date: 2014-07-18 14:53:44 +0800
comments: true
categories: [tools, ganglia]
---

对使用C写的复杂的程序安装心里有阴影，还有本来可以上网的话，使用yum安装会省很多的事情。
但是没办法，环境是这样，正式环境没有提供网络环境，搭建的本地yum环境也不知道行不行。

上次在自己电脑的虚拟机上面成功安装过ganglia，但apache、rrdtool依赖使用yum安装的，安装过程比较揪心。把ganglia安装到正式环境就不了了之的。
上个星期生产环境出现了用户查询数据久久不能返回的问题，由于查询程序写的比较差的缘故。但同时也给自己敲了警钟，都不知道集群机器运行情况，终究是大隐患；安装后监测集群同时为以后程序的调优工作带来便利。

本次安装全部使用源码包安装，有部分lib有重复编译。总结下，原来安装ganglia就仅是按照网络的步骤一步步的弄，同时各个程序的版本又有可能不一致，每一步都胆战心惊！没有重点重心，以至于浪费了很多的事情。
安装ganglia主要涉及三个核心部分(安装程序包[下载](http://yunpan.cn/QCFUiuyAWSyZI)（提取码：0ec4）)：

* rrdtool
* gmetad / gmond
* apache / web
* 配置hadoop metrics监控hadoop集群

进行拆分后，就一个个的安装就可以了。无需为一个个依赖的版本不一致问题而忧心，同时可以更好的参考网络上的实践。

## 安装rrdtool

推荐按照[官网的教程](http://oss.oetiker.ch/rrdtool/doc/rrdbuild.en.html#IBUILDING_DEPENDENCIES)步骤操作，很详细。
教程中环境变量必须得设置！这个很重点！

下面是安装rrdtool过程中用到的软件，列出的顺序即为安装的次序：

```
[hadoop@umcc97-44 rrdbuild]$ ll -tr | grep -v 'tar'
总计 24132
drwxrwxrwx  6   1000          1000    4096 07-17 12:12 pkg-config-0.23
drwxr-xr-x 11 hadoop            80    4096 07-17 12:28 zlib-1.2.3
drwxr-xr-x  7   1004 avahi-autoipd    4096 07-17 12:29 libpng-1.2.18
drwxr-xr-x  8   1000 users            4096 07-17 12:31 freetype-2.3.5
drwxrwxrwx 15  50138 vcsa            12288 07-17 16:37 libxml2-2.6.32
drwxrwxrwx 15   1488 users            4096 07-17 16:53 fontconfig-2.4.2
drwxrwxrwx  4 sjyw   sjyw             4096 07-17 16:56 pixman-0.10.0
drwxrwsrwx  8   1000 ftp              4096 07-17 16:59 cairo-1.6.4
drwxrwxrwx 12 sjyw   sjyw             4096 07-17 17:01 glib-2.15.4
drwxrwxrwx  9 sjyw   sjyw             4096 07-17 17:16 pango-1.21.1
drwxr-xr-x 11   1003          1001    4096 07-17 17:36 rrdtool-1.4.8
```

具体操作的步骤，下面操作相当于历史记录，试错的命令也包括在里面！

```
BUILD_DIR=/home/ganglia/rrdbuild
INSTALL_DIR=/opt/rrdtool-1.4.8

export PKG_CONFIG_PATH=${INSTALL_DIR}/lib/pkgconfig
export PATH=$INSTALL_DIR/bin:$PATH

export LDFLAGS="-Wl,--rpath -Wl,${INSTALL_DIR}/lib" 

[root@umcc97-44 rrdbuild]# tar zxvf pkg-config-0.23.tar.gz 
[root@umcc97-44 rrdbuild]# cd pkg-config-0.23
[root@umcc97-44 pkg-config-0.23]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC"
[root@umcc97-44 pkg-config-0.23]# make && make install

[root@umcc97-44 pkg-config-0.23]# export PKG_CONFIG=$INSTALL_DIR/bin/pkg-config
[root@umcc97-44 pkg-config-0.23]# cd ..

# 想碰运气, 一开始就安装一个后面的, 但是...
[root@umcc97-44 rrdbuild]# cd cairo-1.6.4
[root@umcc97-44 cairo-1.6.4]#  ./configure --prefix=$INSTALL_DIR \
>     --enable-xlib=no \
>     --enable-xlib-render=no \
>     --enable-win32=no \
>     CFLAGS="-O3 -fPIC"
...
checking whether cairo's PNG backend could be enabled... no
configure: error: requested PNG backend could not be enabled

[root@umcc97-44 cairo-1.6.4]# cd ..
[root@umcc97-44 rrdbuild]# tar zxvf libpng-1.2.18.tar.gz 
[root@umcc97-44 rrdbuild]# cd libpng-1.2.18
[root@umcc97-44 libpng-1.2.18]# env CFLAGS="-O3 -fPIC" ./configure --prefix=$INSTALL_DIR
...
checking for zlibVersion in -lz... no
configure: error: zlib not installed

[root@umcc97-44 libpng-1.2.18]# cd ..
[root@umcc97-44 rrdbuild]# tar zxvf zlib-1.2.3.tar.gz 
[root@umcc97-44 rrdbuild]# cd zlib-1.2.3
[root@umcc97-44 zlib-1.2.3]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC" --shared
unknown option: CFLAGS=-O3 -fPIC
./configure --help for help
[root@umcc97-44 zlib-1.2.3]# ./configure 
[root@umcc97-44 zlib-1.2.3]# make && make install

[root@umcc97-44 zlib-1.2.3]# cd ../libpng-1.2.18
[root@umcc97-44 libpng-1.2.18]# ./configure  --prefix=$INSTALL_DIR
[root@umcc97-44 libpng-1.2.18]# make && make install
...
/usr/bin/ld: /usr/local/lib/libz.a(crc32.o): relocation R_X86_64_32 against `a local symbol' can not be used when making a shared object; recompile with -fPIC
/usr/local/lib/libz.a: could not read symbols: Bad value
collect2: ld returned 1 exit status
make[1]: *** [libpng12.la] Error 1
make[1]: Leaving directory `/home/ganglia/rrdbuild/libpng-1.2.18'
make: *** [all] Error 2
[root@umcc97-44 libpng-1.2.18]# cd ../zlib-1.2.3

# 64位问题 recompile with -fPIC
[root@umcc97-44 zlib-1.2.3]# CFLAGS="-O3 -fPIC" ./configure
[root@umcc97-44 zlib-1.2.3]# make && make install

[root@umcc97-44 zlib-1.2.3]# cd ../libpng-1.2.18
[root@umcc97-44 libpng-1.2.18]# make && make install

[root@umcc97-44 libpng-1.2.18]# cd ..
[root@umcc97-44 rrdbuild]# tar zxvf freetype-2.3.5.tar.gz 
[root@umcc97-44 rrdbuild]# cd freetype-2.3.5
[root@umcc97-44 freetype-2.3.5]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC"
[root@umcc97-44 freetype-2.3.5]# make && make install

# 终端断了，需要重新设置4个重要的环境变量
[root@umcc97-44 rrdbuild]# tar zxvf libxml2-2.6.32.tar.gz 
[root@umcc97-44 rrdbuild]# cd libxml2-2.6.32
[root@umcc97-44 libxml2-2.6.32]# BUILD_DIR=/home/ganglia/rrdbuild
[root@umcc97-44 libxml2-2.6.32]# INSTALL_DIR=/opt/rrdtool-1.4.8
[root@umcc97-44 libxml2-2.6.32]# export LDFLAGS="-Wl,--rpath -Wl,${INSTALL_DIR}/lib"
 
[root@umcc97-44 libxml2-2.6.32]#  ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC"
[root@umcc97-44 libxml2-2.6.32]# make && make install

[root@umcc97-44 libxml2-2.6.32]# cd ..
[root@umcc97-44 rrdbuild]# tar zxvf fontconfig-2.4.2.tar.gz 
[root@umcc97-44 rrdbuild]# cd fontconfig-2.4.2
[root@umcc97-44 fontconfig-2.4.2]#  ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC" --with-freetype-config=$INSTALL_DIR/bin/freetype-config
...
checking for LIBXML2... configure: error: Package requirements (libxml-2.0 >= 2.6) were not met:

No package 'libxml-2.0' found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables LIBXML2_CFLAGS
and LIBXML2_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

# 设置PKG_CONFIG
[root@umcc97-44 fontconfig-2.4.2]# export PKG_CONFIG=$INSTALL_DIR/bin/pkg-config
[root@umcc97-44 fontconfig-2.4.2]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC" --with-freetype-config=$INSTALL_DIR/bin/freetype-config
[root@umcc97-44 fontconfig-2.4.2]# make && make install

[root@umcc97-44 fontconfig-2.4.2]# cd ..
[root@umcc97-44 rrdbuild]# cd pixman-0.10.0
[root@umcc97-44 pixman-0.10.0]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC"
[root@umcc97-44 pixman-0.10.0]# make && make install

[root@umcc97-44 pixman-0.10.0]# cd ../cairo-1.6.4
[root@umcc97-44 cairo-1.6.4]# ./configure --prefix=$INSTALL_DIR \
>     --enable-xlib=no \
>     --enable-xlib-render=no \
>     --enable-win32=no \
>     CFLAGS="-O3 -fPIC"
[root@umcc97-44 cairo-1.6.4]# make && make install

[root@umcc97-44 cairo-1.6.4]# cd ..
[root@umcc97-44 rrdbuild]# tar zxvf glib-2.15.4.tar.gz 
[root@umcc97-44 rrdbuild]# cd glib-2.15.4
[root@umcc97-44 glib-2.15.4]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC"
[root@umcc97-44 glib-2.15.4]# make && make install

[root@umcc97-44 rrdbuild]# bunzip2 -c pango-1.21.1.tar.bz2 | tar xf -
[root@umcc97-44 rrdbuild]# ll
[root@umcc97-44 rrdbuild]# cd pango-1.21.1
[root@umcc97-44 pango-1.21.1]#  ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC" --without-x
#! configure后没执行make install

[root@umcc97-44 pango-1.21.1]# cd ../rrdtool-1.4.8/
[root@umcc97-44 rrdtool-1.4.8]# ./configure --prefix=$INSTALL_DIR --disable-tcl --disable-python
# 检查不通过

[root@umcc97-44 rrdtool-1.4.8]# LDFLAGS=-Wl,--rpath -Wl,/opt/rrdtool-1.4.8/lib
[root@umcc97-44 rrdtool-1.4.8]# export LDFLAGS="-Wl,--rpath -Wl,-L/opt/rrdtool-1.4.8/lib"
[root@umcc97-44 rrdtool-1.4.8]# export PKG_CONFIG_PATH=/opt/rrdtool-1.4.8/lib/pkgconfig/
[root@umcc97-44 rrdtool-1.4.8]# ./configure --prefix=$INSTALL_DIR --disable-tcl --disable-python
...
configure: error: Please fix the library issues listed above and try again.

# pango没有make!!
[root@umcc97-44 rrdtool-1.4.8]# cd ../pango-1.21.1
[root@umcc97-44 pango-1.21.1]# ./configure --prefix=$INSTALL_DIR CFLAGS="-O3 -fPIC" --without-x
[root@umcc97-44 pango-1.21.1]# make && make install
...
	&& echo timestamp > s-enum-types-h
/bin/sh: line 1: glib-mkenums: command not found
make[2]: *** [s-enum-types-h] Error 127
make[2]: Leaving directory `/home/ganglia/rrdbuild/pango-1.21.1/pango'
make[1]: *** [all-recursive] Error 1
make[1]: Leaving directory `/home/ganglia/rrdbuild/pango-1.21.1'
make: *** [all] Error 2
# 配置PATH环境变量
[root@umcc97-44 pango-1.21.1]# export PATH=$INSTALL_DIR/bin:$PATH
[root@umcc97-44 pango-1.21.1]# make && make install

## 吃饭回来后，终端又断了，环境变量需要重新设置
[root@umcc97-44 rrdbuild]# BUILD_DIR=/home/ganglia/rrdbuild
[root@umcc97-44 rrdbuild]# INSTALL_DIR=/opt/rrdtool-1.4.8
[root@umcc97-44 rrdbuild]# export LDFLAGS="-Wl,--rpath -Wl,${INSTALL_DIR}/lib" 
[root@umcc97-44 rrdbuild]# export PKG_CONFIG_PATH=${INSTALL_DIR}/lib/pkgconfig
[root@umcc97-44 rrdbuild]# export PATH=$INSTALL_DIR/bin:$PATH
[root@umcc97-44 rrdbuild]# 
[root@umcc97-44 rrdbuild]# cd rrdtool-1.4.8/
[root@umcc97-44 rrdtool-1.4.8]#  ./configure --prefix=$INSTALL_DIR --disable-tcl --disable-python
[root@umcc97-44 rrdtool-1.4.8]# make clean
[root@umcc97-44 rrdtool-1.4.8]# make 
[root@umcc97-44 rrdtool-1.4.8]# make install
   
## 安装完后，搞个例子玩玩   
[root@umcc97-44 rrdtool-1.4.8]# cd /opt/rrdtool-1.4.8/share/rrdtool/examples/
[root@umcc97-44 examples]# ll
[root@umcc97-44 examples]# ./4charts.pl 
This script has created 4charts.png in the current directory
This demonstrates the use of the TIME and % RPN operators
# 运行完后，会在当前目录生成不同尺寸的png的图片
 
[hadoop@umcc97-44 ~]$ /opt/rrdtool-1.4.8/bin/rrdtool -v
RRDtool 1.4.8  Copyright 1997-2013 by Tobias Oetiker <tobi@oetiker.ch>
               Compiled Jul 17 2014 17:37:58

Usage: rrdtool [options] command command_options
Valid commands: create, update, updatev, graph, graphv,  dump, restore,
		last, lastupdate, first, info, fetch, tune,
		resize, xport, flushcached

RRDtool is distributed under the Terms of the GNU General
Public License Version 2. (www.gnu.org/copyleft/gpl.html)

For more information read the RRD manpages
```

到这里rrd安装好，找对了资料按照步骤一步步的操作心里踏实，做事情自然就顺畅！

同时认识到了pkg，其实类似于java的jar嘛，依赖包不一定非要安装在系统的默认位置，自己管理也是一种简单易行的方式。接下来安装gmetad/gmond也使用这样方式，为后面部署gmond带来便利，所有依赖的包都放在一个目录下嘛！
接下来ganglia程序。

## gmetad安装

需要用到的软件包：

```
./gangliabuild/ganglia-web-3.5.12
./gangliabuild/apr-1.5.1
./gangliabuild/apr-util-1.5.3
./gangliabuild/confuse-2.7
./gangliabuild/expat-2.0.1
./gangliabuild/ganglia-3.6.0
```

整个安装过程，除了make的时刻rrd的库找不到的问题（通过LD_LIBRARY_PATH解决），其他都安装的很顺。

```
[root@umcc97-44 gangliabuild]#  cd ganglia-3.6.0
# 开始就碰一鼻子灰！
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=/opt/ganglia --with-librrd=/opt/rrdtool-1.4.8 
...
No package 'apr-1' found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables APR_CFLAGS
and APR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

[root@umcc97-44 ganglia-3.6.0]# cd ..
[root@umcc97-44 gangliabuild]# ll
total 5612
-rw-rw-r--  1 hadoop hadoop 1020833 Jul 17 18:52 apr-1.5.1.tar.gz
-rw-rw-r--  1 hadoop hadoop  874462 Jun 23 20:58 apr-util-1.5.3.tar.gz
-rw-rw-r--  1 hadoop hadoop  517272 Jul 17 18:35 confuse-2.7.tar.gz
-rw-rw-r--  1 hadoop hadoop  446456 Jul 17 18:35 expat-2.0.1.tar.gz
drwxr-xr-x 18 root   root      4096 Jul 17 18:36 ganglia-3.6.0
-rw-rw-r--  1 hadoop hadoop 1248273 Jun 23 19:57 ganglia-3.6.0.tar.gz
drwxr-xr-x 16   1000   1000    4096 Jan  6  2014 ganglia-web-3.5.12
-rw-rw-r--  1 hadoop hadoop 1595483 Jun 23 20:00 ganglia-web-3.5.12.tar.gz
[root@umcc97-44 gangliabuild]# 

[root@umcc97-44 gangliabuild]# find . -name "*.tar.gz" -exec tar zxvf {} \;

[root@umcc97-44 gangliabuild]# cd expat-2.0.1
[root@umcc97-44 expat-2.0.1]# INSTALL_DIR=/opt/ganglia
[root@umcc97-44 expat-2.0.1]# ./configure --prefix=$INSTALL_DIR 
[root@umcc97-44 expat-2.0.1]# make && make install

[root@umcc97-44 expat-2.0.1]# cd ../apr-1.5.1
[root@umcc97-44 apr-1.5.1]# ./configure --prefix=$INSTALL_DIR 
[root@umcc97-44 apr-1.5.1]# make && make install

# 没写prefix，后面又回来重编译
[root@umcc97-44 apr-1.5.1]# cd ../apr-util-1.5.3
[root@umcc97-44 apr-util-1.5.3]# ./configure --with-apr=/opt/ganglia --with-expat=/opt/ganglia
[root@umcc97-44 apr-util-1.5.3]# make && make install
[root@umcc97-44 apr-util-1.5.3]# ./configure --with-apr=/opt/ganglia --with-expat=/opt/ganglia --prefix=$INSTALL_DIR 
[root@umcc97-44 apr-util-1.5.3]# make && make install

[root@umcc97-44 apr-util-1.5.3]# cd ../confuse-2.7
[root@umcc97-44 confuse-2.7]# ./configure CFLAGS=-fPIC --disable-nls --prefix=$INSTALL_DIR 
[root@umcc97-44 confuse-2.7]# make && make install

[root@umcc97-44 confuse-2.7]# cd ../ganglia-3.6.0
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR --with-librrd=/opt/rrdtool-1.4.8 --with-libexpat=/opt/ganglia --with-libconfuse=/opt/ganglia  --with-gmetad --enable-gexec --enable-status -sysconfdir=/etc/ganglia
...
Checking for apr
checking for APR... no
configure: error: Package requirements (apr-1) were not met:

No package 'apr-1' found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables APR_CFLAGS
and APR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

[root@umcc97-44 ganglia-3.6.0]# export LDFLAGS="-Wl,--rpath -Wl,${INSTALL_DIR}/lib" 
[root@umcc97-44 ganglia-3.6.0]# export PKG_CONFIG_PATH=${INSTALL_DIR}/lib/pkgconfig
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR --with-librrd=/opt/rrdtool-1.4.8 --with-libexpat=/opt/ganglia --with-libconfuse=/opt/ganglia  --with-gmetad --enable-gexec --enable-status -sysconfdir=/etc/ganglia
...
libpcre not found, specify --with-libpcre=no to build without PCRE support

[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR --with-librrd=/opt/rrdtool-1.4.8 --with-libexpat=/opt/ganglia --with-libconfuse=/opt/ganglia --with-libpcre=no  --with-gmetad --enable-gexec --enable-status -sysconfdir=/etc/ganglia
...
Welcome to..
     ______                  ___
    / ____/___ _____  ____ _/ (_)___ _
   / / __/ __ `/ __ \/ __ `/ / / __ `/
  / /_/ / /_/ / / / / /_/ / / / /_/ /
  \____/\__,_/_/ /_/\__, /_/_/\__,_/
                   /____/

Copyright (c) 2005 University of California, Berkeley

Version: 3.6.0
Library: Release 3.6.0 0:0:0

Type "make" to compile.

[root@umcc97-44 ganglia-3.6.0]# 
[root@umcc97-44 ganglia-3.6.0]# make && make install
...
/usr/bin/ld: cannot find -lrrd
collect2: ld returned 1 exit status
make[2]: *** [gmetad] Error 1
make[2]: Leaving directory `/home/ganglia/gangliabuild/ganglia-3.6.0/gmetad'
make[1]: *** [all-recursive] Error 1
make[1]: Leaving directory `/home/ganglia/gangliabuild/ganglia-3.6.0'
make: *** [all] Error 2

# 设置rrd的LIB路径
[root@umcc97-44 ganglia-3.6.0]# export LD_LIBRARY_PATH=/opt/rrdtool-1.4.8/lib
[root@umcc97-44 ganglia-3.6.0]# make
[root@umcc97-44 ganglia-3.6.0]# make install
```

接下来是配置gmetad

```
[root@umcc97-44 ganglia-3.6.0]#  cd gmetad
[root@umcc97-44 gmetad]# cp gmetad.init /etc/init.d/gmetad

# 这个配置的位置是不对的，下面配置gmond的时刻会改，移动到/etc/ganglia目录下
[root@umcc97-44 gmetad]# cp gmetad.conf /etc/gmetad.conf
[root@umcc97-44 gmetad]# chkconfig gmetad on

[root@umcc97-44 gmetad]# chkconfig --list gmetad
gmetad         	0:off	1:off	2:on	3:on	4:on	5:on	6:off

[root@umcc97-44 gmetad]# mkdir -p /var/lib/ganglia/rrds
[root@umcc97-44 gmetad]# chown nobody:nobody /var/lib/ganglia/rrds
[root@umcc97-44 gmetad]# 
[root@umcc97-44 gmetad]# service gmetad start
Starting GANGLIA gmetad: 
[root@umcc97-44 gmetad]# 
[root@umcc97-44 gmetad]# cat gmetad.init
[root@umcc97-44 gmetad]# /usr/sbin/gmetad
-bash: /usr/sbin/gmetad: No such file or directory
[root@umcc97-44 gmetad]# ln -s /opt/ganglia/sbin/gmetad /usr/sbin/gmetad
[root@umcc97-44 gmetad]# service gmetad start
Starting GANGLIA gmetad: [  OK  ]

[root@umcc97-44 gmetad]# vi /etc/gmetad.conf 
 datasource "hadoop" localhost
 rrd_rootdir "/var/lib/ganglia/rrds"

[root@umcc97-44 gmetad]# service gmetad restart
Shutting down GANGLIA gmetad: [  OK  ]

Starting GANGLIA gmetad: [  OK  ]

[root@umcc97-44 gmetad]# telnet localhost 8651
```

## gmond安装

```
[root@umcc97-44 gmetad]# pwd
/home/ganglia/gangliabuild/ganglia-3.6.0/gmetad
[root@umcc97-44 gmetad]# cd ..
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR 
...
checking for pcre_compile in -lpcre... no
libpcre not found, specify --with-libpcre=no to build without PCRE support
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR  --with-libpcre=no
...
Welcome to..
     ______                  ___
    / ____/___ _____  ____ _/ (_)___ _
   / / __/ __ `/ __ \/ __ `/ / / __ `/
  / /_/ / /_/ / / / / /_/ / / / /_/ /
  \____/\__,_/_/ /_/\__, /_/_/\__,_/
                   /____/

Copyright (c) 2005 University of California, Berkeley

Version: 3.6.0
Library: Release 3.6.0 0:0:0

Type "make" to compile.
# 尽管检查通过了，但是make会报错

[root@umcc97-44 ganglia-3.6.0]# make && make install
...
ganglia.c:8:19: error: expat.h: No such file or directory
ganglia.c: In function ‘gexec_cluster’:
ganglia.c:255: error: ‘XML_Parser’ undeclared (first use in this function)
ganglia.c:255: error: (Each undeclared identifier is reported only once
ganglia.c:255: error: for each function it appears in.)
ganglia.c:255: error: expected ‘;’ before ‘xml_parser’
ganglia.c:276: error: ‘xml_parser’ undeclared (first use in this function)
...
make[2]: *** [ganglia.lo] Error 1
make[2]: Leaving directory `/home/ganglia/gangliabuild/ganglia-3.6.0/lib'
make[1]: *** [all-recursive] Error 1
make[1]: Leaving directory `/home/ganglia/gangliabuild/ganglia-3.6.0'
make: *** [all] Error 2

# 需要指定lib包位置
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR  --with-libpcre=no  --with-libexpat=/opt/ganglia --with-libconfuse=/opt/ganglia
[root@umcc97-44 ganglia-3.6.0]# make
[root@umcc97-44 ganglia-3.6.0]# make install

[root@umcc97-44 ganglia-3.6.0]# cd gmond/
[root@umcc97-44 gmond]# ./gmond -t > /etc/gmond.conf
[root@umcc97-44 gmond]# cat gmond.init
#!/bin/sh
#
# chkconfig: 2345 70 40
# description: gmond startup script
#
GMOND=/usr/sbin/gmond

...
[root@umcc97-44 gmond]# ln -s /opt/ganglia/sbin/gmond /usr/sbin/gmond
[root@umcc97-44 gmond]# cp gmond.init /etc/init.d/gmond
[root@umcc97-44 gmond]# chkconfig --add gmond
[root@umcc97-44 gmond]# chkconfig --list gmond
gmond          	0:off	1:off	2:on	3:on	4:on	5:on	6:off
[root@umcc97-44 gmond]# service gmond start
Starting GANGLIA gmond: Configuration file '/opt/ganglia/etc/gmond.conf' not found.

[  OK  ]

[root@umcc97-44 gmond]# service gmond stop
Shutting down GANGLIA gmond: [  OK  ]

# 配置目录不对再编一次
[root@umcc97-44 gmond]# cd ..
[root@umcc97-44 ganglia-3.6.0]# ./configure --prefix=$INSTALL_DIR  --with-libpcre=no  --with-libexpat=/opt/ganglia --with-libconfuse=/opt/ganglia -sysconfdir=/etc/ganglia
[root@umcc97-44 ganglia-3.6.0]# make && make install

[root@umcc97-44 etc]# mv gmetad.conf ganglia/
mv: overwrite `ganglia/gmetad.conf'? Y
[root@umcc97-44 etc]# mv gmond.conf ganglia/
[root@umcc97-44 etc]# 

[root@umcc97-44 ganglia-3.6.0]# vi /etc/ganglia/gmond.conf 
 cluster-name

[root@umcc97-44 ganglia-3.6.0]# service gmond restart
Shutting down GANGLIA gmond: [  OK  ]

Starting GANGLIA gmond: [  OK  ]

[root@umcc97-44 ganglia-3.6.0]# telnet localhost 8649
```

查看运行情况：

```
[root@umcc97-44 ganglia-3.6.0]# ldconfig -v
[root@umcc97-44 ganglia-3.6.0]#  /opt/ganglia/bin/gstat -a
```

## apache和php环境安装

```
[root@umcc97-44 webbuild]# tar zxvf httpd-2.4.9.tar.gz 
[root@umcc97-44 webbuild]# cd httpd-2.4.9
[root@umcc97-44 httpd-2.4.9]# ./configure -with-enable-so -sysconfdir=/etc/httpd
...
checking for APR... no
configure: error: APR not found.  Please read the documentation.

# 前面安装ganglia时也安装过APR但是安装的目录指定的，混用不是很好。查看官方安装2.4的安装文档，可以直接把apr放到srclib下，编译时会同时编译这些依赖
[root@umcc97-44 httpd-2.4.9]# cd srclib/
[root@umcc97-44 srclib]# cp -r /home/ganglia/gangliabuild/apr-1.5.1 ./
[root@umcc97-44 srclib]# cp -r /home/ganglia/gangliabuild/apr-util-1.5.3 ./
[root@umcc97-44 srclib]# mv apr-1.5.1 apr
[root@umcc97-44 srclib]# mv apr-util-1.5.3 apr-util
[root@umcc97-44 srclib]# ll
[root@umcc97-44 srclib]# cd ..
[root@umcc97-44 httpd-2.4.9]# ./configure --with-included-apr -with-enable-so -sysconfdir=/etc/httpd
...
checking for pcre-config... false
configure: error: pcre-config for libpcre not found. PCRE is required and available from http://pcre.org/

[root@umcc97-44 httpd-2.4.9]#  cd ../
[root@umcc97-44 webbuild]# tar zxvf pcre-8.35.tar.gz 
# 正则表达式的包，这里安装默认位置
[root@umcc97-44 webbuild]# cd pcre-8.35
[root@umcc97-44 pcre-8.35]# ./configure 
[root@umcc97-44 pcre-8.35]# make && make install

[root@umcc97-44 pcre-8.35]# cd ../httpd-2.4.9
[root@umcc97-44 httpd-2.4.9]# ./configure --with-included-apr -with-enable-so -sysconfdir=/etc/httpd
[root@umcc97-44 httpd-2.4.9]# make && make install

[root@umcc97-44 httpd-2.4.9]# cd /usr/local/apache2/
[root@umcc97-44 apache2]# cd /etc/httpd

[root@umcc97-44 httpd]# cd /home/ganglia/webbuild/
[root@umcc97-44 webbuild]# tar zxvf php-5.5.14\ \(2\).tar.gz 
[root@umcc97-44 webbuild]# cd php-5.5.14
# 用了安装rrd时的libxml
[root@umcc97-44 php-5.5.14]# ./configure -with-apxs2=/usr/local/apache2/bin/apxs --with-libxml-dir=/opt/rrdtool-1.4.8/ -sysconfdir=/etc -with-config-file-path=/etc -with-config-file-scan-dir=/usr/etc/php.d -with-zlib
[root@umcc97-44 php-5.5.14]# make && make install

[root@umcc97-44 php-5.5.14]#  
[root@umcc97-44 php-5.5.14]#  vi /etc/httpd/httpd.conf
 DocumentRoot "/var/www/html"
 <Directory "/var/www/html">
 PHP Module
 ADDType

[root@umcc97-44 php-5.5.14]# /usr/local/apache2/bin/apachectl start
AH00526: Syntax error on line 215 of /etc/httpd/httpd.conf:
DocumentRoot must be a directory

[root@umcc97-44 php-5.5.14]# mkdir -p /var/www/html
[root@umcc97-44 php-5.5.14]# /usr/local/apache2/bin/apachectl start
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.18.97.44. Set the 'ServerName' directive globally to suppress this message

[root@umcc97-44 php-5.5.14]#  vi /etc/httpd/httpd.conf
 ServerName
[root@umcc97-44 php-5.5.14]#/usr/local/apache2/bin/apachectl start
httpd (pid 31416) already running

[root@umcc97-44 php-5.5.14]# cp /usr/local/apache2/bin/apachectl /etc/init.d/httpd
[root@umcc97-44 php-5.5.14]# chkconfig --add httpd
service httpd does not support chkconfig

[root@umcc97-44 ~]# vi /etc/init.d/httpd 
 #chkconfig: 2345 10 90
 #description: Activates/Deactivates Apache Web Server
 
[root@umcc97-44 ~]# service httpd start

[root@umcc97-44 ~]# cd /var/www/html/
[root@umcc97-44 ~]# vi index.php
# http://umcc97-44 浏览器查看下结果

# /usr/local/apache2/bin/apachectl -k stop
[root@umcc97-44 ganglia-web]# service httpd -k stop	
# 等apache结束
[root@umcc97-44 ganglia-web]# tail -f /usr/local/apache2/logs/error_log 
```

部署ganglia-web： 

```
[root@umcc97-44 ~]# cd /home/ganglia/gangliabuild/ganglia-web-3.5.12
[root@umcc97-44 ganglia-web-3.5.12]# ls
[root@umcc97-44 ganglia-web-3.5.12]# make install
rsync --exclude "rpmbuild" --exclude "*.gz" --exclude "Makefile" --exclude "*debian*" --exclude "ganglia-web-3.5.12" --exclude ".git*" --exclude "*.in" --exclude "*~" --exclude "#*#" --exclude "ganglia-web.spec" --exclude "apache.conf" -a . ganglia-web-3.5.12
mkdir -p //var/lib/ganglia-web/dwoo/compiled && \
	mkdir -p //var/lib/ganglia-web/dwoo/cache && \
	mkdir -p //var/lib/ganglia-web && \
	rsync -a ganglia-web-3.5.12/conf //var/lib/ganglia-web && \
	mkdir -p //usr/share/ganglia-webfrontend && \
	rsync --exclude "conf" -a ganglia-web-3.5.12/* //usr/share/ganglia-webfrontend && \
	chown -R root:root //var/lib/ganglia-web

[root@umcc97-44 ganglia-web-3.5.12]# mv /usr/share/ganglia-webfrontend /var/www/html/ganglia
[root@umcc97-44 ganglia-web-3.5.12]# cd /var/www/html/ganglia/	
[root@umcc97-44 ganglia]# cp conf_default.php conf.php	

[root@umcc97-44 ganglia]# cd /var/lib/ganglia-web/
[root@umcc97-44 ganglia-web]# cd dwoo/
[root@umcc97-44 dwoo]# ll
total 8
drwxr-xr-x 2 root root 4096 Jul 17 21:34 cache
drwxr-xr-x 2 root root 4096 Jul 17 21:34 compiled
[root@umcc97-44 dwoo]# chmod 777 *	
# http://umcc97-44/ganglia
```

部署gmond到其他集群节点

```

[root@umcc97-44 opt]# cat /etc/init.d/gmond 
#!/bin/sh
#
# chkconfig: 2345 70 40
# description: gmond startup script
#
GMOND=/usr/sbin/gmond	

[root@umcc97-44 opt]# vi /etc/ganglia/gmetad.conf 	
 data_source
 # 重启gmetad
[root@umcc97-44 opt]# ssh-copy-id -i ~/.ssh/id_rsa.pub umcc97-144
[root@umcc97-44 opt]# scp /etc/init.d/gmond umcc97-144:/etc/init.d/
[root@umcc97-44 opt]# ssh umcc97-144 'mkdir /etc/ganglia' 
[root@umcc97-44 opt]# scp /etc/ganglia/gmond.conf  umcc97-144:/etc/ganglia/
[root@umcc97-44 opt]# rsync -vaz ganglia umcc97-144:/opt/
[root@umcc97-44 opt]# ssh umcc97-144
Last login: Tue Jun 10 12:08:47 2014

[root@umcc97-144 ~]# ln -s /opt/ganglia/sbin/gmond /usr/sbin/gmond
[root@umcc97-144 ~]# chkconfig --add gmond
[root@umcc97-144 ~]# service gmond start
Starting GANGLIA gmond: [  OK  ]

[root@umcc97-144 ~]# 
```

## Hadoop/Hbase Metrics配置 

```
[hadoop@umcc97-44 ~]$ cat hadoop-2.2.0/etc/hadoop/hadoop-metrics*
#
#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# syntax: [prefix].[source|sink].[instance].[options]
# See javadoc of package-info.java for org.apache.hadoop.metrics2 for details

# @changed
#*.sink.file.class=org.apache.hadoop.metrics2.sink.FileSink
# default sampling period, in seconds
#*.period=10

# The namenode-metrics.out will contain metrics from all context
#namenode.sink.file.filename=namenode-metrics.out
# Specifying a special sampling period for namenode:
#namenode.sink.*.period=8

#datanode.sink.file.filename=datanode-metrics.out

# the following example split metrics of different
# context to different sinks (in this case files)
#jobtracker.sink.file_jvm.context=jvm
#jobtracker.sink.file_jvm.filename=jobtracker-jvm-metrics.out
#jobtracker.sink.file_mapred.context=mapred
#jobtracker.sink.file_mapred.filename=jobtracker-mapred-metrics.out

#tasktracker.sink.file.filename=tasktracker-metrics.out

#maptask.sink.file.filename=maptask-metrics.out

#reducetask.sink.file.filename=reducetask-metrics.out



*.sink.ganglia.class=org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31
*.sink.ganglia.period=10

*.sink.ganglia.slope=jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both
*.sink.ganglia.dmax=jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40

namenode.sink.ganglia.servers=umcc97-44:8649
resourcemanager.sink.ganglia.servers=umcc97-44:8649

datanode.sink.ganglia.servers=umcc97-44:8649
nodemanager.sink.ganglia.servers=umcc97-44:8649

maptask.sink.ganglia.servers=umcc97-44:8649
reducetask.sink.ganglia.servers=umcc97-44:8649



# Configuration of the "dfs" context for null
dfs.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "dfs" context for file
#dfs.class=org.apache.hadoop.metrics.file.FileContext
#dfs.period=10
#dfs.fileName=/tmp/dfsmetrics.log

# Configuration of the "dfs" context for ganglia
# Pick one: Ganglia 3.0 (former) or Ganglia 3.1 (latter)
# dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# dfs.period=10
# dfs.servers=localhost:8649


# Configuration of the "mapred" context for null
mapred.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "mapred" context for file
#mapred.class=org.apache.hadoop.metrics.file.FileContext
#mapred.period=10
#mapred.fileName=/tmp/mrmetrics.log

# Configuration of the "mapred" context for ganglia
# Pick one: Ganglia 3.0 (former) or Ganglia 3.1 (latter)
# mapred.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# mapred.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# mapred.period=10
# mapred.servers=localhost:8649


# Configuration of the "jvm" context for null
#jvm.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "jvm" context for file
#jvm.class=org.apache.hadoop.metrics.file.FileContext
#jvm.period=10
#jvm.fileName=/tmp/jvmmetrics.log

# Configuration of the "jvm" context for ganglia
# jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# jvm.period=10
# jvm.servers=localhost:8649

# Configuration of the "rpc" context for null
rpc.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "rpc" context for file
#rpc.class=org.apache.hadoop.metrics.file.FileContext
#rpc.period=10
#rpc.fileName=/tmp/rpcmetrics.log

# Configuration of the "rpc" context for ganglia
# rpc.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# rpc.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# rpc.period=10
# rpc.servers=localhost:8649


# Configuration of the "ugi" context for null
ugi.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "ugi" context for file
#ugi.class=org.apache.hadoop.metrics.file.FileContext
#ugi.period=10
#ugi.fileName=/tmp/ugimetrics.log

# Configuration of the "ugi" context for ganglia
# ugi.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# ugi.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# ugi.period=10
# ugi.servers=localhost:8649

[hadoop@umcc97-44 ~]$ cat hbase-0.98.3-hadoop2/conf/hadoop-metrics2-hbase.properties 
# syntax: [prefix].[source|sink].[instance].[options]
# See javadoc of package-info.java for org.apache.hadoop.metrics2 for details

#*.sink.file*.class=org.apache.hadoop.metrics2.sink.FileSink
# default sampling period
#*.period=10

# Below are some examples of sinks that could be used
# to monitor different hbase daemons.

# hbase.sink.file-all.class=org.apache.hadoop.metrics2.sink.FileSink
# hbase.sink.file-all.filename=all.metrics

# hbase.sink.file0.class=org.apache.hadoop.metrics2.sink.FileSink
# hbase.sink.file0.context=hmaster
# hbase.sink.file0.filename=master.metrics

# hbase.sink.file1.class=org.apache.hadoop.metrics2.sink.FileSink
# hbase.sink.file1.context=thrift-one
# hbase.sink.file1.filename=thrift-one.metrics

# hbase.sink.file2.class=org.apache.hadoop.metrics2.sink.FileSink
# hbase.sink.file2.context=thrift-two
# hbase.sink.file2.filename=thrift-one.metrics

# hbase.sink.file3.class=org.apache.hadoop.metrics2.sink.FileSink
# hbase.sink.file3.context=rest
# hbase.sink.file3.filename=rest.metrics


*.sink.ganglia.class=org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31
*.sink.ganglia.period=10

hbase.sink.ganglia.period=10
hbase.sink.ganglia.servers=umcc97-44:8649

```

然后properties配置同步到集群的从节点（datanode/regionserver），重启集群。等一会儿就能在ganglia-web界面看到多了很多很多的指标量。

## 参考

### ganglia

* [RRDTool安装](http://oss.oetiker.ch/rrdtool/doc/rrdbuild.en.html#IBUILDING_DEPENDENCIES)
* [CFLAGS="-O3 -fPIC"为64位编译参数](http://www.cnblogs.com/qq78292959/archive/2012/05/30/2526761.html)
* [pkgconfig作用处理包依赖](http://www.codesky.net/article/201107/174186.html)
* [gmetad和gmond安装以及配置](http://blog.chinaunix.net/uid-23916356-id-3290237.html)
* [gmond节点拷贝安装](http://wenku.baidu.com/link?url=RH4EhSP3U_dp4I7goEVA_DFkb0DrgZ3uWw_mSt2hhaRb6mQJLtWxaa75RrwETwtY5e8BvOCI_p9RNrmXn_qbEexTE-PGlgtf6f5T3cGglKq)
* <http://blog.chinaunix.net/uid-11121450-id-3147002.html>
* <http://blog.chinaunix.net/uid-23916356-id-3290237.html>
* [虚拟机操作从零开始弄, 搭了个本地源, 配置](http://wenku.baidu.com/link?url=qY7vCTyodgSCsoIg6c2UiHXWv0nEGkS9nd0DbQERxFGEaTvgvi7FMQTKv5Sn1L9H8CX5_gDgAbJJ5jaQh3KhZED7PoB2Bgr2I6mS-vDc1LS)
* [Hadoop/Hbase metrics2配置](http://www.linuxidc.com/Linux/2014-01/95804p2.htm)
* <https://github.com/cbuchner1/CudaMiner/issues/23>
* <http://bbs.csdn.net/topics/390546319> LIBRARY_PATH是编译时使用的，LD_LIBRARY_PATH是运行时使用的。

### apache web

* [apache程序安装](http://blog.sina.com.cn/s/blog_70121e200100lq0h.html)
* [apache服务安装配置](http://blog.sina.com.cn/s/blog_5d15305b0101ceft.html)
* [apache关闭服务](http://www.cnblogs.com/yuboyue/archive/2011/07/18/2109875.html)
* [目录权限处理](http://www.soadmin.com/zonghe/operating-system/1008085.htm)
* <http://blog.163.com/figo_2007@126/blog/static/2318076520111149413935/>
* <http://blog.sina.com.cn/s/blog_70121e200100lq0h.html>
* <http://blog.sina.com.cn/s/blog_815611fb0101cxnl.html>
