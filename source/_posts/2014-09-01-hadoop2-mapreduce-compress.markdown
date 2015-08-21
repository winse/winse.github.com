---
layout: post
title: "hadoop2 mapreduce输入输出压缩"
date: 2014-09-01 16:05:13 +0800
comments: true
categories: [hadoop]
---

当数据达到一定量时，自然就想到了对数据进行压缩来降低存储压力。在Hadoop的任务中提供了5个参数来控制输入输出的数据的压缩格式。添加map输出数据压缩可以降低集群间的网络传输，最终reduce输出压缩可以减低hdfs的集群存储空间。

如果是使用hive等工具的话，效果会更加明显。因为hive的查询结果是临时存储在hdfs中，然后再通过一个**Fetch Operator**来获取数据，最后清理掉，压缩存储临时的数据可以减少磁盘的读写。

```
<property>
  <name>mapreduce.output.fileoutputformat.compress</name>
  <value>false</value>
  <description>Should the job outputs be compressed?
  </description>
</property>

<property>
  <name>mapreduce.output.fileoutputformat.compress.type</name>
  <value>RECORD</value>
  <description>If the job outputs are to compressed as SequenceFiles, how should
               they be compressed? Should be one of NONE, RECORD or BLOCK.
  </description>
</property>

<property>
  <name>mapreduce.output.fileoutputformat.compress.codec</name>
  <value>org.apache.hadoop.io.compress.DefaultCodec</value>
  <description>If the job outputs are compressed, how should they be compressed?
  </description>
</property>

<property>
  <name>mapreduce.map.output.compress</name>
  <value>false</value>
  <description>Should the outputs of the maps be compressed before being
               sent across the network. Uses SequenceFile compression.
  </description>
</property>

<property>
  <name>mapreduce.map.output.compress.codec</name>
  <value>org.apache.hadoop.io.compress.DefaultCodec</value>
  <description>If the map outputs are compressed, how should they be 
               compressed?
  </description>
</property>
```

上面5个属性弄好，在core-sitem.xml加下`io.compression.codecs`基本就完成配置了。

这里主要探究下mapreduce（下面全部简称MR）过程中自动解压缩。刚刚接触Hadoop一般都不会去了解什么压缩不压缩的，先把hdfs-api，MR-api弄一遭。配置的TextInputFormat竟然能正确的读取tar.gz文件的内容，觉得不可思议，TextInputFormat不是直接读取txt行记录的输入嘛？难道还能读取压缩文件，先解压再...？？

先说下OutputFormat，在MR中调用context.write写入数据的方法时，最终使用OutputFormat创建的RecordWriter进行持久化。在TextOutputFormat创建RecordWriter时，如果使用压缩会在结果文件名上**加对应压缩库的后缀**，如gzip压缩对应的后缀gz、snappy压缩对应后缀snappy等。对应下面代码的`getDefaultWorkFile`。

![](http://file.bmob.cn/M00/0B/03/wKhkA1QEjD2ASHiZAAExjXuQ25Y062.png)

同样对应的TextInputFormat的RecordReader也进行类似的处理：根据**文件的后缀**来判定该文件是否使用压缩，并使用对应的输入流InputStream来解码。

![](http://file.bmob.cn/M00/0B/03/wKhkA1QEjZaAdBeJAAEvRVMKVWY059.png)

此处的关键代码为`CompressionCodec codec = new CompressionCodecFactory(job).getCodec(file);`，根据分块（split）的文件名来判断使用的压缩算法。
初始化Codec实现、以及根据文件名来获取压缩算法的实现还是挺有意思的：通过反转字符串然后最近匹配（headMap）来获取对应的结果。

```
  private void addCodec(CompressionCodec codec) {
    String suffix = codec.getDefaultExtension();
    codecs.put(new StringBuilder(suffix).reverse().toString(), codec);
    codecsByClassName.put(codec.getClass().getCanonicalName(), codec);

    String codecName = codec.getClass().getSimpleName();
    codecsByName.put(codecName.toLowerCase(), codec);
    if (codecName.endsWith("Codec")) {
      codecName = codecName.substring(0, codecName.length() - "Codec".length());
      codecsByName.put(codecName.toLowerCase(), codec);
    }
  }

  public CompressionCodec getCodec(Path file) {
    CompressionCodec result = null;
    if (codecs != null) {
      String filename = file.getName();
      String reversedFilename = new StringBuilder(filename).reverse().toString();
      SortedMap<String, CompressionCodec> subMap = 
        codecs.headMap(reversedFilename);
      if (!subMap.isEmpty()) {
        String potentialSuffix = subMap.lastKey();
        if (reversedFilename.startsWith(potentialSuffix)) {
          result = codecs.get(potentialSuffix);
        }
      }
    }
    return result;
  }
``` 

了解了这些，MR（TextInputFormat）的输入文件可以比较随意些：各种压缩文件、原始文件都可以，只要文件有对应压缩算法的后缀即可。hive的解压缩功能也很容易了，如果使用hive存储text形式的文件，进行压缩无需进行额外的程序代码修改，仅仅修改MR的配置即可，注意下**文件后缀**！！

如，在MR中生成了snappy压缩的文件，此时**不能**在文件的后面添加东西。否则在hive查询时，根据**后缀**进行解压会导致结果乱码/不正确。

```
<property>
  <name>hive.exec.compress.output</name>
  <value>false</value>
  <description> This controls whether the final outputs of a query (to a local/hdfs file or a hive table) is compressed. The compression codec and other options are determined from hadoop config variables mapred.output.compress* </description>
</property>

<property>
  <name>hive.exec.compress.intermediate</name>
  <value>false</value>
  <description> This controls whether intermediate files produced by hive between multiple map-reduce jobs are compressed. The compression codec and other options are determined from hadoop config variables mapred.output.compress* </description>
</property>

```

hive也弄了两个参数来控制它自己的MR的输出输入压缩控制属性。其他的配置使用mapred-site.xml的配置即可。

![](http://file.bmob.cn/M00/0B/1D/wKhkA1QFQLmAfyZSAAIOx4UEIbY016.png)

网上一些资料有`hive.intermediate.compression.codec`和`hive.intermediate.compression.type`两个参数能调整中间过程的压缩算法。其实和mapreduce的参数功能是一样的。

![](http://file.bmob.cn/M00/0B/1F/wKhkA1QFQWyAUDMLAAGyNqR_X-c417.png)

附上解压缩的全部配置：

```
$#core-site.xml
	<property>
		<name>io.compression.codecs</name>
		<value>
	org.apache.hadoop.io.compress.GzipCodec,
	org.apache.hadoop.io.compress.DefaultCodec,
	org.apache.hadoop.io.compress.BZip2Codec,
	org.apache.hadoop.io.compress.SnappyCodec
		</value>
	</property>

$#mapred-site.xml
	<property>
		<name>mapreduce.map.output.compress</name> 
		<value>true</value>
	</property>
	<property>
		<name>mapreduce.map.output.compress.codec</name>
		<value>org.apache.hadoop.io.compress.SnappyCodec</value>
	</property>

	<property>
		<name>mapreduce.output.fileoutputformat.compress</name>
		<value>true</value>
	</property>

	<property>
		<name>mapreduce.output.fileoutputformat.compress.codec</name>
		<value>org.apache.hadoop.io.compress.SnappyCodec</value>
	</property>
	<property>
		<name>mapred.output.compression.codec</name>
		<value>org.apache.hadoop.io.compress.SnappyCodec</value>
	</property>

$#hive-site.xml
	<property>
		<name>hive.exec.compress.output</name>
		<value>true</value>
	</property>
```

运行hive后，临时存储在HDFS的结果数据，注意文件的后缀。

![](http://file.bmob.cn/M00/0B/20/wKhkA1QFRjSACnLfAABVdoK0f1c803.png)

## 参考

* [深入学习《Programing Hive》：数据压缩](http://www.geek521.com/?p=4814)