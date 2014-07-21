---
layout: post
title: "Ant实现hadoop插件Run-on-Hadoop"
date: 2013-03-27 18:53
comments: true
categories: [hadoop]
---

撇开eclipse的插件不说，如果直接在eclipse运行main方法，运行的时刻会提示map，reduce找不到的错误。其实就是没有把需要类的包提供给集群环境。

看过使用hadoop-eclipse-plugin插件（[http://winseclone.iteye.com/blog/1837035](/blog/1837035)）最后解析的Run-on-Hadoop的实现，不难得出下面的方法步骤：

* 首先打包jar，
* 然后把jar的路径给Main的-Dmapred.jar参数。

这样，就可以把环境需要的class上传到hadoop了。

主要的ant代码如下：

```
	<property name="exported.jar" value="${build.dir}/tmp-runonhadoop-${now}.jar"></property>

	<target name="jar" depends="build" description="Make tmp-run.jar">
		<jar jarfile="${exported.jar}" basedir="${build.classes}">
			<fileset dir="${build.classes}" includes="**/example/*" />
			<exclude name="**/core-site.xml"/>
		</jar>
	</target>

	<target name="WordCount" depends="build, jar" >
		<java classname="com.winse.hadoop.examples.WordCount" failonerror="true" fork="yes">
			<arg line="-fs=${fs.default.name} -jt=${mapred.job.tracker} -Dmapred.jar=${exported.jar} /test/input /test/output"/>

			<classpath refid="runon.classpath"/>
		</java>
	</target>
```

## [源码](http://dl.iteye.com/topics/download/267b989c-3422-3fe8-b1c8-c4550accac6b)：

其实就[build.xml](https://gist.github.com/winse/9564525)重要，其他就是exmaples里面的wordcount的源码而已。
其实build.xml也不重要，重要的思路！思路清晰了做事情就八九不离十了！  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1837531)
