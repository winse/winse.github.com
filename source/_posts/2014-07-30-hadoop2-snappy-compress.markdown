---
layout: post
title: "hadoop2 snappy compress"
date: 2014-07-30 00:25:39 +0800
comments: true
categories: [hadoop]
---

网上查了很多资料说的很复杂，要叉叉叉叉叉！其实hadoop2已经集成了hadoop-snappy，只要安装snappy即可。但是也没有一些文章说的只要编译snappy然后放到lib/native路径下即可，还需要重新编译libhadoop的library包。

查找hadoop-snappy的源码的时刻，在C代码里面定义了`HADOOP_SNAPPY_LIBRARY`，然后理着这个思路去查找，发现在CMakeFile文件中也定义了对应的变量，然后再查找pom.xml的native profile中定义了snappy.prefix的属性。最后就有了下面的步骤。

1) build snappy

编译Snappy，并把lib拷贝/同步到hadoop的native目录下。

```
tar zxf snappy-1.1.1.tar.gz 
cd snappy-1.1.1
./configure --prefix=/home/hadoop/snappy
make
make install

cd snappy
cd lib/
rysnc -vaz * ~/hadoop-2.2.0/lib/native/
```

2) rebuild hadoop common project

重新编译hadoop的lib，覆盖原来的文件。

```
[hadoop@master1 hadoop-common]$ mvn package -Dmaven.javadoc.skip=true -DskipTests -Dsnappy.prefix=/home/hadoop/snappy -Drequire.snappy=true -Pnative 

[hadoop@master1 hadoop-common]$ cd ~/hadoop-2.2.0-src/hadoop-common-project/hadoop-common/
[hadoop@master1 hadoop-common]$ cd target/native/target/usr/local/lib/
[hadoop@master1 lib]$ ll
total 1252
-rw-rw-r--. 1 hadoop hadoop 820824 Jul 30 00:18 libhadoop.a
lrwxrwxrwx. 1 hadoop hadoop     18 Jul 30 00:18 libhadoop.so -> libhadoop.so.1.0.0
-rwxrwxr-x. 1 hadoop hadoop 455542 Jul 30 00:18 libhadoop.so.1.0.0
[hadoop@master1 lib]$ rsync -vaz * ~/hadoop-2.2.0/lib/native/
sending incremental file list
libhadoop.a
libhadoop.so.1.0.0

sent 409348 bytes  received 53 bytes  818802.00 bytes/sec
total size is 1276384  speedup is 3.12
[hadoop@master1 lib]$ 
```

3) check

检查程序snappy是否已经配置成功

```
[hadoop@master1 ~]$ hadoop checknative -a
14/07/30 00:22:14 WARN bzip2.Bzip2Factory: Failed to load/initialize native-bzip2 library system-native, will use pure-Java version
14/07/30 00:22:14 INFO zlib.ZlibFactory: Successfully loaded & initialized native-zlib library
Native library checking:
hadoop: true /home/hadoop/hadoop-2.2.0/lib/native/libhadoop.so.1.0.0
zlib:   true /lib64/libz.so.1
snappy: true /home/hadoop/hadoop-2.2.0/lib/native/libsnappy.so.1
lz4:    true revision:43
bzip2:  false 
14/07/30 00:22:14 INFO util.ExitUtil: Exiting with status 1
[hadoop@master1 ~]$ 
```

4) 跑一个压缩程序

先参考网上的，直接用hbase的带的测试类运行（前提：需要在hbase-env.sh中配置HADOOP_HOME，这样hbase才能找到hadoop下的lib本地库）

```
[hadoop@master1 ~]$ hbase-0.98.3-hadoop2/bin/hbase org.apache.hadoop.hbase.util.CompressionTest file:///tmp/abc.snappy snappy
2014-07-30 08:50:42,617 INFO  [main] Configuration.deprecation: hadoop.native.lib is deprecated. Instead, use io.native.lib.available
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/home/hadoop/hbase-0.98.3-hadoop2/lib/slf4j-log4j12-1.6.4.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/home/hadoop/hadoop-2.2.0/share/hadoop/common/lib/slf4j-log4j12-1.7.5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
2014-07-30 08:50:44,515 INFO  [main] util.ChecksumType: Checksum using org.apache.hadoop.util.PureJavaCrc32
2014-07-30 08:50:44,522 INFO  [main] util.ChecksumType: Checksum can use org.apache.hadoop.util.PureJavaCrc32C
2014-07-30 08:50:45,388 INFO  [main] compress.CodecPool: Got brand-new compressor [.snappy]
2014-07-30 08:50:45,408 INFO  [main] compress.CodecPool: Got brand-new compressor [.snappy]
2014-07-30 08:50:45,430 ERROR [main] hbase.KeyValue: Unexpected getShortMidpointKey result, fakeKey:testkey, firstKeyInBlock:testkey
2014-07-30 08:50:47,088 INFO  [main] compress.CodecPool: Got brand-new decompressor [.snappy]
SUCCESS
[hadoop@master1 ~]$ 
```

看到最后的**SUCCESS**就说明安装配置成功了！

接下来自己写程序测试压缩/解压缩，首先编写java类：

```
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.io.compress.CompressionCodec;
import org.apache.hadoop.io.compress.CompressionInputStream;
import org.apache.hadoop.io.compress.CompressionOutputStream;
import org.apache.hadoop.io.compress.SnappyCodec;
import org.apache.hadoop.util.ReflectionUtils;
import org.apache.zookeeper.common.IOUtils;

public class SnappyCompressTest {

        public static void main(String[] args) throws FileNotFoundException, IOException {
                try {
                        execute(args);
                } catch (Exception e) {
                        System.out.println("Usage: $0 read|write file[.snappy]");
                }
        }

        private static void execute(String[] args) throws FileNotFoundException, IOException {
                String op = args[0];
                String file = args[1];
                String snappyFile = file + ".snappy";

                Class<? extends CompressionCodec> clazz = SnappyCodec.class;
                CompressionCodec codec = ReflectionUtils.newInstance(clazz, new Configuration());

                if (StringUtils.equalsIgnoreCase(op, "read")) {
                        FileInputStream fin = new FileInputStream(snappyFile);
                        CompressionInputStream in = codec.createInputStream(fin);
                        FileOutputStream fout = new FileOutputStream(file);
                        IOUtils.copyBytes(in, fout, 4096, true);
                } else {
                        FileInputStream fin = new FileInputStream(file);
                        CompressionOutputStream out = codec.createOutputStream(new FileOutputStream(snappyFile));
                        IOUtils.copyBytes(fin, out, 4096, true);
                }
        }

}
```

编译运行，测试读写功能。使用hadoop命令可以简化很多工作，把当前路径加入到`HADOOP_CLASSPATH`。

```
[hadoop@master1 test]$ javac -cp `hadoop classpath` SnappyCompressTest.java 
[hadoop@master1 test]$ export HADOOP_CLASSPATH=$PWD
[hadoop@master1 test]$ hadoop SnappyCompressTest 
Usage: $0 read|write file[.snappy]
[hadoop@master1 test]$ hadoop SnappyCompressTest write test.txt 
[hadoop@master1 test]$ ll
total 16
-rw-rw-r--. 1 hadoop hadoop 1991 Jul 30 09:27 SnappyCompressTest.class
-rw-rw-r--. 1 hadoop hadoop 1586 Jul 30 09:23 SnappyCompressTest.java
-rw-rw-r--. 1 hadoop hadoop   12 Jul 30 09:23 test.txt
-rw-rw-r--. 1 hadoop hadoop   22 Jul 30 09:28 test.txt.snappy
[hadoop@master1 test]$ rm test.txt
[hadoop@master1 test]$ hadoop SnappyCompressTest read test.txt 
[hadoop@master1 test]$ ll
total 16
-rw-rw-r--. 1 hadoop hadoop 1991 Jul 30 09:27 SnappyCompressTest.class
-rw-rw-r--. 1 hadoop hadoop 1586 Jul 30 09:23 SnappyCompressTest.java
-rw-rw-r--. 1 hadoop hadoop   12 Jul 30 09:28 test.txt
-rw-rw-r--. 1 hadoop hadoop   22 Jul 30 09:28 test.txt.snappy
[hadoop@master1 test]$ cat test.txt
abc
abc
abc
```

5) hbase中添加压缩

把所有library，以及hbase的配置同步其他所有从节点。对hbase的表使用Snappy压缩。

```
hbase(main):001:0> create 'st1', 'f1'
hbase(main):005:0> alter 'st1', {NAME=>'f1', COMPRESSION=>'snappy'}
Updating all regions with the new schema...
0/1 regions updated.
1/1 regions updated.
Done.
0 row(s) in 2.7880 seconds

hbase(main):010:0> create 'sst1','f1'
0 row(s) in 0.5730 seconds

=> Hbase::Table - sst1
hbase(main):011:0> flush 'sst1'
0 row(s) in 2.5380 seconds

hbase(main):012:0> flush 'st1'
0 row(s) in 7.5470 seconds
```

对于hbase来说，使用压缩消耗还是挺大的。插入10w数据中间进行compaction时停顿比较久。最后flush写数据的时间也长了很多！
下面是文件写入后的文件大小对比（由于是进行简单的测试，写入的数据重复比较多。具体比例没有参考价值）：

![](http://file.bmob.cn/M00/05/5A/wKhkA1PYz9CAB-TdAAEWX8LGpUo149.png)

