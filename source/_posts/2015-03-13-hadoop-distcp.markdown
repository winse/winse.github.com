---
layout: post
title: "hadoop distcp"
date: 2015-03-13 20:38:23 +0800
comments: true
categories: [hadoop]
---

HDFS提供的CP是单线程的，对于大数据量的拷贝操作希望能并行的复制。Hadoop Tools提供了DistCp工具，通过调用MapRed来实现并行的拷贝。

## 先来了解下hdfs cp的功能：

```
Usage: hdfs dfs -cp [-f] [-p | -p[topax]] URI [URI ...] <dest>

[hadoop@hadoop-master2 hadoop-2.6.0]$ hadoop fs -cp /cp /cp-not-exists
[hadoop@hadoop-master2 hadoop-2.6.0]$ hadoop fs -mkdir /cp-exists
[hadoop@hadoop-master2 hadoop-2.6.0]$ hadoop fs -cp /cp /cp-exists
[hadoop@hadoop-master2 hadoop-2.6.0]$ hadoop fs -cp /cp /cp-not-exists2/
cp: `/cp-not-exists2/': No such file or directory
[hadoop@hadoop-master2 hadoop-2.6.0]$ hadoop fs -ls -R /
drwxr-xr-x   - hadoop supergroup          0 2015-03-14 19:55 /cp
-rw-r--r--   1 hadoop supergroup       1366 2015-03-14 19:55 /cp/README.1.txt
-rw-r--r--   1 hadoop supergroup       1366 2015-03-14 19:54 /cp/README.txt
drwxr-xr-x   - hadoop supergroup          0 2015-03-14 20:17 /cp-exists
drwxr-xr-x   - hadoop supergroup          0 2015-03-14 20:17 /cp-exists/cp
-rw-r--r--   1 hadoop supergroup       1366 2015-03-14 20:17 /cp-exists/cp/README.1.txt
-rw-r--r--   1 hadoop supergroup       1366 2015-03-14 20:17 /cp-exists/cp/README.txt
drwxr-xr-x   - hadoop supergroup          0 2015-03-14 20:17 /cp-not-exists
-rw-r--r--   1 hadoop supergroup       1366 2015-03-14 20:17 /cp-not-exists/README.1.txt
-rw-r--r--   1 hadoop supergroup       1366 2015-03-14 20:17 /cp-not-exists/README.txt
```

## DistCp(distributed copy)分布式拷贝简单使用方式：

```
[hadoop@hadoop-master2 hadoop-2.6.0]$ bin/hadoop distcp /cp /cp-distcp
```

用到分布式一般就说明规模不少，且数据量大，操作时间长。DistCp提供了一些参数来控制程序：

| DistCpOptionSwitch选项    | 命令行参数                      | 描述                                        |
|:--------------------------|:-------------------------------:|:---------------------------------------------
| LOG_PATH                  | `-log <logdir>                ` | map结果输出的目录。默认为`JobStagingDir/_logs`，在DistCp#configureOutputFormat把该路径设置给CopyOutputFormat#setOutputPath。
| SOURCE_FILE_LISTING       | `-f <urilist_uri>             ` | 需要拷贝的source-path...从改文件获取。
| MAX_MAPS                  | `-m <num_maps>                ` | 默认20个，创建job时通过`JobContext.NUM_MAPS`添加到配置。
| ATOMIC_COMMIT             | `-atomic                      ` | 原子操作。要么全部拷贝成功，那么失败。与`SYNC_FOLDERS` & `DELETE_MISSING`选项不兼容。
| WORK_PATH                 | `-tmp <tmp_dir>               ` | 与atomic一起使用，中间过程存储数据目录。成功后在CopyCommitter一次性移动到target-path下。
| SYNC_FOLDERS              | `-update                      ` | 新建或更新文件。当文件大小和blockSize（以及crc）一样忽略。
| DELETE_MISSING            | `-delete                      ` | 针对target-path目录，清理source-paths目录下没有的文件。常和`SYNC_FOLDERS`选项一起使用。
| BLOCKING                  | `-async                       ` | 异步运行。其实就是job提交后，不打印日志了没有调用`job.waitForCompletion(true)`罢了。
| BANDWIDTH                 | `-bandwidth num(M)            ` | 获取数据的最大速度。结合ThrottledInputStream来进行控制，在RetriableFileCopyCommand中初始化。
| COPY_STRATEGY             | `-strategy dynamic/uniformsize` | 复制的时刻分组策略，即每个Map到底处理写什么数据。后面会讲到，分为静态和动态。

还有新增的两个属性skipcrccheck（SKIP_CRC），append（APPEND）。保留Preserve 属性和ssl选项由于暂时没用到，这里不表，以后用到再补充。

## DistCp的源码

放在`hadoop-2.6.0-src\hadoop-tools\hadoop-distcp`目录下。

```
mvn eclipse:eclipse 
```

网络没问题的话，一般都能成功生成.classpath和.project两个Eclipse需要的项目文件。然后把项目导入eclipse即可。包括4个目录。

还是先说说整个distcp的实现流程，看看distcp怎么跑的。

```
[hadoop@hadoop-master2 ~]$ export HADOOP_CLIENT_OPTS="-Dhadoop.root.logger=debug,console -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8071"
[hadoop@hadoop-master2 ~]$ hadoop distcp /cp /cp-distcp
Listening for transport dt_socket at address: 8071
```

运行eclipse远程调试，连接服务器的8071端口，在DistCp的run方法打个断点，就可以调试了解其运行方式。修改log4j为debug，可以查看更详细的日志，了解执行的流程。

服务器的jdk版本和本地eclipse的jdk版本最好一致，这样调试的时刻比较顺畅。

### Driver

首先进到DistCp(Driver)的main方法，DistCp继承Configured实现了Tool接口，

第一步解析参数

1. 使用`ToolRunner.run`运行会调用GenericOptionsParser解析`-D`的属性到Configuration实例；
2. 进到run方法后，通过`OptionsParser.parse`来解析配置为DistCpOptions实例；功能比较单一，主要涉及到DistCpOptionSwitch和DistCpOptions两个类。

第二步准备MapRed的Job实例

1. 创建metaFolderPath（后面的 待拷贝文件seq文件存取的位置：StagingDir/_distcp[RAND]），对应`CONF_LABEL_META_FOLDER`属性；
2. 创建Job，设置名称、InputFormat(UniformSizeInputFormat|DynamicInputFormat)、Map类CopyMapper、Map个数（默认20个）、Reduce个数（0个）、OutputKey|ValueClass、MAP_SPECULATIVE（使用RetriableCommand代替）、CopyOutputFormat
3. 把命令行的配置写入Configuration。

```
metaFolderPath /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp-1344594636
```

此处有话题，设置InputFormat时通过`DistCpUtils#getStrategy`获取，代码中并没有`strategy.impl`的键加入到configuration。why？此处也是我们可以学习的，这个设置项在distcp-default.xml配置文件中，这种方式可以实现代码的解耦。

```
  public static Class<? extends InputFormat> getStrategy(Configuration conf,
                                                                 DistCpOptions options) {
    String confLabel = "distcp." +
        options.getCopyStrategy().toLowerCase(Locale.getDefault()) + ".strategy.impl";
    return conf.getClass(confLabel, UniformSizeInputFormat.class, InputFormat.class);
  }

// 配置
    <property>
        <name>distcp.dynamic.strategy.impl</name>
        <value>org.apache.hadoop.tools.mapred.lib.DynamicInputFormat</value>
        <description>Implementation of dynamic input format</description>
    </property>

    <property>
        <name>distcp.static.strategy.impl</name>
        <value>org.apache.hadoop.tools.mapred.UniformSizeInputFormat</value>
        <description>Implementation of static input format</description>
    </property>
```

配置CopyOutputFormat时，设置了三个路径：

* WorkingDirectory（中间临时存储目录，atomic选项时为tmp路径，否则为target-path路径）；
* CommitDirectory（文件拷贝最终目录，即target-path）；
* OutputPath（map write记录输出路径）。

关于命令行选项有一个疑问，用eclipse查看`Call Hierachy`调用关系的时刻，并没有发现调用`DistCpOptions#getXXX`的方法，那么是通过什么方式把这些配置项设置到Configuration的呢？ 在DistCpOptionSwitch的枚举类中定义了每个选项的confLabel，在`DistCpOptions#appendToConf`方法中一起把这些属性填充到Configuration中。 [统一配置] ！！

```
  public void appendToConf(Configuration conf) {
    DistCpOptionSwitch.addToConf(conf, DistCpOptionSwitch.ATOMIC_COMMIT,
        String.valueOf(atomicCommit));
    DistCpOptionSwitch.addToConf(conf, DistCpOptionSwitch.IGNORE_FAILURES,
        String.valueOf(ignoreFailures));
...
```

第三步整理需要拷贝的文件列表

这个真tmd的独到，提前把要做的事情规划好。需要拷贝的列表数据最终写入`[metaFolder]/fileList.seq`（key：与source-path的相对路径，value：该文件的CopyListingFileStatus），对应`CONF_LABEL_LISTING_FILE_PATH`，也就是map的输入（在自定义的InputFormat中处理）。

涉及CopyList的三个实现FileBasedCopyListing（-f）、GlobbedCopyListing、SimpleCopyListing。最终都调用SimpleCopyListing把文件和空目录列表写入到fileList.seq；最后校验否有重复的文件名，如果存在会抛出DuplicateFileException。

```
/tmp/hadoop-yarn/staging/hadoop/.staging/_distcp179796572/fileList.seq
```

同时计算需要拷贝的个数和大小（Byte），对应`CONF_LABEL_TOTAL_BYTES_TO_BE_COPIED`和`CONF_LABEL_TOTAL_NUMBER_OF_RECORDS`。

第四步提交任务，等待等待无尽的等待。

也可以设置async选项，提交成功后直接完成Driver。

### Mapper

首先，setup从Configuration中获取配置属性：sync(update)/忽略错误(i)/校验码/overWrite/workPath/finalPath

然后，从CONF_LABEL_LISTING_FILE_PATH路径获取准备好的sourcepath->CopyListingFileStatus键值对作为map的输入。

其实CopyListingFileStatus这个对象真正用到的就是原始Path的路径，真心不知道搞这么多属性干嘛！获取原始路径后又重新实例CopyListingFileStatus为sourceCurrStatus。

* 如果源路径为文件夹，调用createTargetDirsWithRetry（RetriableDirectoryCreateCommand）创建路径，COPY计数加1，return。
* 如果源路径为文件，但是checkUpdate（文件大小和块大小一致）为skip，SKIP计数加1，BYTESSKIPPED计数加上sourceCurrStatus的长度，把改条记录写入map输出，return。
* 如果源路径为文件，且检查后不是skip则调用copyFileWithRetry（RetriableFileCopyCommand）拷贝文件，BYTESEXPECTED计数加上sourceCurrStatus的长度，BYTESCOPIED计数加上拷贝文件的大小，COPY计数加1，再return。
* 如果配置有保留文件/文件夹属性，对目标进行属性修改。

从CopyListing获取数据，调用FileSystem-IO接口进行数据的拷贝（在原有IO的基础上封装了ThrottledInputStream来进行限流处理）。于此同时会涉及到source路径是文件夹但是target不是文件夹等的检查；更新还是覆盖；文件属性的保留和Map计数值的更新操作。

### InputFormat

自定义了InputFormat来UniformSizeInputFormat进行拆分构造FileSplit，对CONF_LABEL_LISTING_FILE_PATH文件的每个键值的文件大小平均分成Map num
个数小块，根据键值的位置构造Map num个FileSplit对象。执行map时，RecordReader根据FileSplit来获取键值对，然后传递给map。

新版本的增加了DynamicInputFormat，实现能者多难的功能。先通过实际的日志，看看运行效果：

```
[hadoop@hadoop-master2 ~]$ export HADOOP_CLIENT_OPTS="-Dhadoop.root.logger=debug,console -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8071"
[hadoop@hadoop-master2 ~]$ hadoop distcp "-Dmapreduce.map.java.opts=-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8090" -strategy dynamic -m 2 /cp /cp-distcp-dynamic

# 创建的chunk
[hadoop@hadoop-master2 ~]$ hadoop fs -ls -R /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446
-rw-r--r--   1 hadoop supergroup        506 2015-03-20 00:40 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/fileList.seq
-rw-r--r--   1 hadoop supergroup        446 2015-03-20 00:40 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/fileList.seq_sorted
[hadoop@hadoop-master2 ~]$ hadoop fs -ls -R /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446
drwx------   - hadoop supergroup          0 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir
-rw-r--r--   1 hadoop supergroup        198 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir/fileList.seq.chunk.00000
-rw-r--r--   1 hadoop supergroup        224 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir/fileList.seq.chunk.00001
-rw-r--r--   1 hadoop supergroup        220 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir/fileList.seq.chunk.00002
-rw-r--r--   1 hadoop supergroup        506 2015-03-20 00:40 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/fileList.seq
-rw-r--r--   1 hadoop supergroup        446 2015-03-20 00:40 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/fileList.seq_sorted

# 分配后的chunk
[hadoop@hadoop-master2 ~]$ hadoop fs -ls -R /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446
drwx------   - hadoop supergroup          0 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir
-rw-r--r--   1 hadoop supergroup        220 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir/fileList.seq.chunk.00002
-rw-r--r--   1 hadoop supergroup        198 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir/task_1426773672048_0006_m_000000
-rw-r--r--   1 hadoop supergroup        224 2015-03-20 00:41 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/chunkDir/task_1426773672048_0006_m_000001
-rw-r--r--   1 hadoop supergroup        506 2015-03-20 00:40 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/fileList.seq
-rw-r--r--   1 hadoop supergroup        446 2015-03-20 00:40 /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446/fileList.seq_sorted

# map获取后
[hadoop@hadoop-master2 ~]$  ssh -g -L 8090:hadoop-slaver1:8090 hadoop-slaver1
# 每拷贝完一个chunk/最后map结束，会把上一个跑完的chunk文件删除
# job跑完后，临时目录的数据就被清楚了
[hadoop@hadoop-master2 ~]$ hadoop fs -ls -R /tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446
ls: `/tmp/hadoop-yarn/staging/hadoop/.staging/_distcp1568928446': No such file or directory
```

由于设置的map num为2，还有一个chunk没有分配出去，等到真正执行的时刻再进行分配。体现了策略的动态性。这个**chunkm_000000分配给map0(其他类似)**，其他没有分配出去的chunk让给map去**抢**。

首先InputFormat创建FileSplit，在此过程中把原来的`CONF_LABEL_LISTING_FILE_PATH`中的需要处理的文件根据个数等份成chunk。（具体实现看源码，其中numEntriesPerChunk计算一个chunk几个文件比较复杂点）

chunk中的也是sourcepath->CopyListingFileStatus键值对，以seq格式的存储文件中。`DynamicInputChunk#acquire(TaskAttemptContext)`读取数据的时刻比较有意思，在Driver阶段分配的chunk处理完后，就会动态的取处理余下的chunk，能者多劳。

```
  public static DynamicInputChunk acquire(TaskAttemptContext taskAttemptContext) throws IOException, InterruptedException {
    if (!areInvariantsInitialized())
        initializeChunkInvariants(taskAttemptContext.getConfiguration());

    String taskId = taskAttemptContext.getTaskAttemptID().getTaskID().toString();
    Path acquiredFilePath = new Path(chunkRootPath, taskId);

    if (fs.exists(acquiredFilePath)) {
      LOG.info("Acquiring pre-assigned chunk: " + acquiredFilePath);
      return new DynamicInputChunk(acquiredFilePath, taskAttemptContext);
    }

    for (FileStatus chunkFile : getListOfChunkFiles()) {
      if (fs.rename(chunkFile.getPath(), acquiredFilePath)) {
        LOG.info(taskId + " acquired " + chunkFile.getPath());
        return new DynamicInputChunk(acquiredFilePath, taskAttemptContext);
      }
      else
        LOG.warn(taskId + " could not acquire " + chunkFile.getPath());
    }

    return null;
  }
```

### OutputFormat & Committer

自定义的CopyOutputFormat包括了working/commit/output路径的get/set方法，同时指定了自定义的OutputCommitter：CopyCommitter。

正常情况为app-master调用CopyCommitter#commitJob处理善后的事情：保留文件属性的情况下更新文件的属性，atomic情况下把working转到commit路径，delete情况下删除target目录多余的文件。最后清理临时目录。

看完DistCp然后再去看DistCpV1，尽管说功能上类似，但是要和新版本对上仍然要去看distcp的代码。好的代码就是这样吧，让人很自然轻松的理解，而不必反复来回的折腾，甚至于为了免得来回折腾而记住该代码块。（类太大，方法太长，变量定义和使用的位置相隔很远！一个变量作用域太长赋值变更次数太多）

## 参考

* [FileSystemShell cp](http://hadoop.apache.org/docs/r2.6.0/hadoop-project-dist/hadoop-common/FileSystemShell.html#cp)
* [DistCp官方文档](http://hadoop.apache.org/docs/r2.6.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/DistCp.html)
