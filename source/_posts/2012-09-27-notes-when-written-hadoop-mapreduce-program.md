---
layout: post
title: "使用hadoop编写mapreduce程序的注意点"
date: 2012-09-27 23-47
comments: true
categories: [hadoop]
---

## 编程时需要注意：

1、实例化job后，不要再使用原来的configuration，得通过job.getCongfigure()来进行参数的配置

```
public static Job createSubmittableJob(Configuration conf, String[] args) 
		throws IOException {
	String tableName = args[0];

	conf.set(TableInputFormat.INPUT_TABLE, tableName);
	conf.set(TableInputFormat.SCAN, 
		ScanAccessor.getTableInputFormatScan(conf, tableName));

	Job job = new Job(conf, 
		Index.class.getSimpleName() + "_" + tableName + ":" + Utils.now());
	job.setJarByClass(Index.class);

	// conf.set(..., ...)设置将不会生效
	job.getConfiguration().set(...
```

2、map输出的keyvalue与reduce的输出keyvalue对象不统一，这种情况不应该把reduce作为combine类。

```
job.setMapperClass(TokenizerMapper.class);
job.setCombinerClass(IntSumReducer.class);
job.setReducerClass(IntSumReducer.class);

job.setMapOutputKeyClass(Text.class);
job.setMapOutputValueClass(FloatWritable.class);

job.setOutputKeyClass(Text.class);
//job.setOutputValueClass(FloatWritable.class);
job.setOutputValueClass(Text.class);
```

这样的错误，出现后，如果不认认真真检查的话，比较难发现问题的！

> 如果map和reduce的keyvalue类型不同时，不要把Reduce的类作为Combine的处理类！

3、聚合类型的操作才使用reduce

1. GOOD： sqoop导数据功能
2. WORSE: hadoop contrib index (详...)

4、命令行参数的顺序

**-D参数，以及Hadoop内置的参数, **必须放在class后面，不能跟在**args**后

**· ERROR**：

% hadoop jar hadoop-*-examples.jar sort -r **numbers.seq sorted** \
-inFormat org.apache.hadoop.mapred.SequenceFileInputFormat \
-outFormat org.apache.hadoop.mapred.SequenceFileOutputFormat \
-outkey org.apache.hadoop.io.IntWritable \
-outvalue org.apache.hadoop.io.Text

**· OK**：

% hadoop jar hadoop-*-examples.jar sort -r \
-inFormat org.apache.hadoop.mapred.SequenceFileInputFormat \
-outFormat org.apache.hadoop.mapred.SequenceFileOutputFormat \
-outkey org.apache.hadoop.io.IntWritable \
-outvalue org.apache.hadoop.io.Text \
**numbers.seq sorted**

## 配置属性注意点：

1. 开启trash
	```
	<property>
	<name>fs.trash.interval</name>
	<value>720</value>
	</property>
	```
2. 去除mapreduce完成后"SUCCESS"，"history目录"
3. 共享jvm
4. 不要关闭mapreduce的超时
	```
	Configuration conf = ...
	conf.set("hadoop.job.history.user.location", "none");
	conf.setBoolean("mapreduce.fileoutputcommitter.marksuccessfuljobs", false);

	conf.set("mapred.job.reuse.jvm.num.tasks", "-1");

	// conf.set("mapred.task.timeout", "0");
	```
	可以在执行任务时，新建一个发送心跳的线程，告诉jobtracker当前的任务没有问题。
5. pid的存放目录最好自定义。长期放置在tmp下的文件将会被清除。
	[http://winseclone.iteye.com/blog/1772989](/blog/1772989)

	```
	export HADOOP_PID_DIR=/var/hadoop/pids
	```

## Hadoop入门资料：

1. 官网
2. [https://ccp.cloudera.com/display/DOC/Hadoop+Tutorial](https://ccp.cloudera.com/display/DOC/Hadoop+Tutorial)


* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1687678)
