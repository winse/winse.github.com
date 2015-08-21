---
layout: post
title: "hadoop上建索引index的程序"
date: 2012-10-01 13-13
comments: true
categories: [hadoop]
---

## 源码

\hadoop-1.0.0\src\contrib\index

## 主要涉及的类

* org.apache.hadoop.contrib.index.main.UpdateIndex
* org.apache.hadoop.contrib.index.mapred.IndexUpdater
* org.apache.hadoop.contrib.index.mapred.IndexUpdateMapper
* org.apache.hadoop.contrib.index.mapred.IndexUpdatePartitioner
* org.apache.hadoop.contrib.index.mapred.IndexUpdateCombiner
* org.apache.hadoop.contrib.index.mapred.IndexUpdateReducer
* org.apache.hadoop.contrib.index.example.LineDocInputFormat
* org.apache.hadoop.contrib.index.mapred.IndexUpdateOutputFormat
* org.apache.hadoop.contrib.index.mapred.IndexUpdateConfiguration

## 解析

1、UpdateIndex类（main实现读取控制台参数）

UpdateIndex是整个程序的入口，提供参数给用户配置。

*   -inputPaths  -->mapred.input.dir  (V)
*   -outputPath -->mapred.output.dir  (V)
*   -shards -->最终每个reduct建立的索引存放hdfs位置 (V)
*   -indexPath -->sea.index.path
*   -numShards -->sea.num.shards
*   -numMapTasks -->mapred.map.tasks  (V)
*   -conf 添加Configuration xml文件形式的配置方式

shards  通过**转换**最终保存到Configuration的sea.index.shards

shards参数 与 indexPath和numShards参数 设置一种就可以了。如果没有设置shards，则在main方法中会通过indexPath和numShards生成得到 shards 参数。

从Configuration中获得Updater类: IndexUpdateConfiguration.getIndexUpdaterClass()

```
  public Class<? extends IIndexUpdater> getIndexUpdaterClass() {
    return conf.getClass("sea.index.updater", IndexUpdater.class,
        IIndexUpdater.class);
  }
```

在UpdateIndex最终调用IndexUpdater

```
updater.run(conf, inputPaths, outputPath, numMapTasks, shards);
```

2、IndexUpdater类（配置MapReduce Job）

```
  public void run(Configuration conf, Path[] inputPaths, Path outputPath,
      int numMapTasks, Shard[] shards) throws IOException {
    JobConf jobConf =
        createJob(conf, inputPaths, outputPath, numMapTasks, shards);
    JobClient.runJob(jobConf);
  }
...
...
  JobConf createJob(Configuration conf, Path[] inputPaths, Path outputPath,
      int numMapTasks, Shard[] shards) throws IOException {
    setShardGeneration(conf, shards);

    // iconf.set sets properties in conf
    IndexUpdateConfiguration iconf = new IndexUpdateConfiguration(conf);
    Shard.setIndexShards(iconf, shards);

    // MapTask.MapOutputBuffer uses "io.sort.mb" to decide its max buffer size
    // (max buffer size = 1/2 * "io.sort.mb").
    // Here we half-en "io.sort.mb" because we use the other half memory to
    // build an intermediate form/index in Combiner.
    iconf.setIOSortMB(iconf.getIOSortMB() / 2);
```

setShardGeneration(conf, shards);方法从shard path路径获得segment_N来获得generation，并更新shard实例的gen属性。

Shard.setIndexShards(iconf, shards);则是序列化shards为String写入到Configuration中。

接下来的代码，就是设置InputFormat，OutputFormat， Map， Reduce，Partitioner，  KeyValue Class， Combine等一些列的Job必备的参数。

```
    // create the job configuration
    JobConf jobConf = new JobConf(conf, IndexUpdater.class);
    jobConf.setJobName(this.getClass().getName() + "_"
        + System.currentTimeMillis());

    // provided by application
    FileInputFormat.setInputPaths(jobConf, inputPaths);
    FileOutputFormat.setOutputPath(jobConf, outputPath);

    jobConf.setNumMapTasks(numMapTasks);

    // already set shards
    jobConf.setNumReduceTasks(shards.length);

    jobConf.setInputFormat(iconf.getIndexInputFormatClass());

    // set by the system
    jobConf.setMapOutputKeyClass(IndexUpdateMapper.getMapOutputKeyClass());
    jobConf.setMapOutputValueClass(IndexUpdateMapper.getMapOutputValueClass());
    jobConf.setOutputKeyClass(IndexUpdateReducer.getOutputKeyClass());
    jobConf.setOutputValueClass(IndexUpdateReducer.getOutputValueClass());

    jobConf.setMapperClass(IndexUpdateMapper.class);
    jobConf.setPartitionerClass(IndexUpdatePartitioner.class);
    jobConf.setCombinerClass(IndexUpdateCombiner.class);
    jobConf.setReducerClass(IndexUpdateReducer.class);

    jobConf.setOutputFormat(IndexUpdateOutputFormat.class);

    return jobConf;
```

3、LineDocInputFormat（数据输入类）

从IndexUpdateConfiguration.getIndexInputFormatClass()可以获得当前默认使用的数据输入类org.apache.hadoop.contrib.index.example.LineDocInputFormat。

这里定义了org.apache.hadoop.contrib.index.example.LineDocRecordReader来解析数据，获取建立索引的命令（Insert， Update， Delete）和对应的数据。

```
  public synchronized boolean next(DocumentID key, LineDocTextAndOp value)
      throws IOException {
    if (pos >= end) {
      return false;
    }

    // key is document id, which are bytes until first space
    if (!readInto(key.getText(), SPACE)) { // 把读到的第一个数据写入Key
      return false;
    }

    // read operation: i/d/u, or ins/del/upd, or insert/delete/update
    Text opText = new Text();
    if (!readInto(opText, SPACE)) {
      return false;
    }
    String opStr = opText.toString();
    DocumentAndOp.Op op;
    if (opStr.equals("i") || opStr.equals("ins") || opStr.equals("insert")) {
      op = DocumentAndOp.Op.INSERT;
    } else if (opStr.equals("d") || opStr.equals("del")
        || opStr.equals("delete")) {
      op = DocumentAndOp.Op.DELETE;
    } else if (opStr.equals("u") || opStr.equals("upd")
        || opStr.equals("update")) {
      op = DocumentAndOp.Op.UPDATE;
    } else {
      // default is insert
      op = DocumentAndOp.Op.INSERT;
    }
    value.setOp(op);

    if (op == DocumentAndOp.Op.DELETE) {
      return true;
    } else {
      // read rest of the line
      return readInto(value.getText(), EOL);
    }
  }
```

把InputStream offset到分隔符的数据写入到text 

```
private boolean readInto(Text text, char delimiter) throws IOException
```

Sample 写道

> 0 ins apache dot org 	
> 2 ins apache 	
> 3 ins apache 	
> 4 ins apache 	
> 	
> 0 del 	
> 1 upd hadoop 	
> 2 del 	
> 3 upd hadoop

4、IndexUpdateMapper（最终形成IntermediateForm传递给Combiner和Reducer处理）

**· ILocalAnalysis** -->org.apache.hadoop.contrib.index.example.LineDocLocalAnalysis

把Text组成为Lucene需要的Document。

**· DocumentAndOp**

```
public class DocumentAndOp implements Writable {

  private Op op; // 
  private Document doc; // INSERT UPDATE
  private Term term; // DELETE UPDATE
```

**· IntermediateForm**

```
public class IntermediateForm implements Writable {

  private final Collection<Term> deleteList;
  private RAMDirectory dir;
  private IndexWriter writer;
  private int numDocs;

  public void process(DocumentAndOp doc, Analyzer analyzer) throws IOException {
    if (doc.getOp() == DocumentAndOp.Op.DELETE
        || doc.getOp() == DocumentAndOp.Op.UPDATE) {
      deleteList.add(doc.getTerm());

    }

    if (doc.getOp() == DocumentAndOp.Op.INSERT
        || doc.getOp() == DocumentAndOp.Op.UPDATE) {

      if (writer == null) {
        // analyzer is null because we specify an analyzer with addDocument
        writer = createWriter();
      }

      writer.addDocument(doc.getDocument(), analyzer);
      numDocs++;
    }

  }

  public void process(IntermediateForm form) throws IOException {
    if (form.deleteList.size() > 0) {
      deleteList.addAll(form.deleteList);
    }

    if (form.dir.sizeInBytes() > 0) {
      if (writer == null) {
        writer = createWriter();
      }

      writer.addIndexesNoOptimize(new Directory[] { form.dir });
      numDocs++;
    }

  }
```

**· HashingDistributionPolicy**

```
public class HashingDistributionPolicy implements IDistributionPolicy {

  private int numShards;

  public void init(Shard[] shards) {
    numShards = shards.length;
  }

  public int chooseShardForInsert(DocumentID key) {
    int hashCode = key.hashCode();
    return hashCode >= 0 ? hashCode % numShards : (-hashCode) % numShards;
  }

  public int chooseShardForDelete(DocumentID key) {
    int hashCode = key.hashCode();
    return hashCode >= 0 ? hashCode % numShards : (-hashCode) % numShards;
  }

}
```

IndexUpdateMapper.**map**(K, V, OutputCollector<Shard, IntermediateForm>, Reporter)

根据DocumentAndOp形成IntermediateForm，以及DistributionPolicy选择Shard，传入Combiner。

评注： 这里每条数据都要开启和关闭Writer，消耗应该不小。

5、IndexUpdateCombiner

把该节点的IntermediateForm合并成一个大的IntermediateForm集合。

评注： 感觉作用不是很大，合并减少的数据量有限； 但是却又要初始化和关闭一次Writer。

6、IndexUpdateReducer

把从Mapper传递来的IntermediateForm写入到ShardWriter。最终把Lucene索引写入到IndexPath下。

```
 public ShardWriter(FileSystem fs, Shard shard, String tempDir,
      IndexUpdateConfiguration iconf) throws IOException
```

在Reducer最后关闭ShardWriter时，由于要等待比较长的时间。这里使用一个新的线程来发送心跳。 [使用hadoop/编写mapreduce程序 注意点](/blog/1687678)(! 不要关闭mapreduce的超时)

```
    new Closeable() {
      volatile boolean closed = false;

      public void close() throws IOException {
        // spawn a thread to give progress heartbeats
        Thread prog = new Thread() {
          public void run() {
            while (!closed) {
              try {
                fReporter.setStatus("closing");
                Thread.sleep(1000);
              } catch (InterruptedException e) {
                continue;
              } catch (Throwable e) {
                return;
              }
            }
          }
        };

        try {
          prog.start();

          if (writer != null) {
            writer.close();
          }
        } finally {
          closed = true;
        }
      }
    }.close();
```

**· ShardWriter**

把索引写到本地，等处理完了数据后，关闭IndexWriter后把索引库转入拷贝到HDFS持久化。

```
  // move the files created in the temp dir into the perm dir
  // and then delete the temp dir from the local FS
  private void moveFromTempToPerm() throws IOException {
    try {
      FileStatus[] fileStatus =
          localFs.listStatus(temp, LuceneIndexFileNameFilter.getFilter());
      Path segmentsPath = null;
      Path segmentsGenPath = null;

      // move the files created in temp dir except segments_N and segments.gen
      for (int i = 0; i < fileStatus.length; i++) {
        Path path = fileStatus[i].getPath();
        String name = path.getName();

        if (LuceneUtil.isSegmentsGenFile(name)) {
          assert (segmentsGenPath == null);
          segmentsGenPath = path;
        } else if (LuceneUtil.isSegmentsFile(name)) {
          assert (segmentsPath == null);
          segmentsPath = path;
        } else {
          fs.completeLocalOutput(new Path(perm, name), path);
        }
      }

      // move the segments_N file
      if (segmentsPath != null) {
        fs.completeLocalOutput(new Path(perm, segmentsPath.getName()),
            segmentsPath);
      }

      // move the segments.gen file
      if (segmentsGenPath != null) {
        fs.completeLocalOutput(new Path(perm, segmentsGenPath.getName()),
            segmentsGenPath);
      }
    } finally {
      // finally delete the temp dir (files should have been deleted)
      localFs.delete(temp);
    }
  }
```

  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1689055)
