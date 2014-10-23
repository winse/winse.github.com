---
layout: post
title: "[读码] Spark1.1.0前篇"
date: 2014-10-12 13:12:57 +0800
comments: true
categories: [spark]
---

看过亚太研究院的spark在线教学视频，说spark1.0的源码仅有3w+的代码，蠢蠢欲动。先具体看下源码的量，估算估算；然后搭建eclipse读码环境。

## 计算源码行数

```
winse@Lenovo-PC ~/git/spark
$ git branch -v
* (detached from v1.1.0) 2f9b2bd [maven-release-plugin] prepare release v1.1.0-rc4
  master                 4d8ae70 [behind 1246] Cleanup on Connection and ConnectionManager

winse@Lenovo-PC ~/git/spark
$ find . -name "*.scala" | grep 'src/main' | xargs sed  -e 's:\/\*.*\*\/::' -e  '/\/\*/, /\*\//{
/\/\*/{
 s:\/\*.*::p
}
/\*\//{
 s:.*\*\/::p
}
d
}' | sed -e '/^\s*$/d' -e '/^\s*\/\//d' | grep -v '^import' | grep -v '^package' | wc -l
72967

winse@Lenovo-PC ~/git/spark
$ ^scala^java
1749

winse@Lenovo-PC ~/git/spark
$ ^src/main^core/src/main
877

winse@Lenovo-PC ~/git/spark
$ ^java^scala
38526

```

全部源码的数量（去掉测试）大概在7W左右，仅计算核心代码core下面的代码量在4W。从量上面来说还是比较乐观的，学习scala然后读spark的源码。

spark1.0.0的核心代码量在3w左右。1.1多了大概1w行！！

## Docker

查看目录结构的时刻，看到spark1下面竟然有docker，不过看Dockerfile的内容只是简单的安装了scala、把本机的spark映射到docker容器、然后运行spark主从集群。

## 导入eclipse

spark使用主要使用scala编写，首先需要下载[scala-ide](http://scala-ide.org/download/sdk.html)直接下载2.10的版本（基于eclipse，很多操作都类似）；然后下载[spark的源码](https://github.com/apache/spark.git)检出v1.1.0的；然后使用maven生成eclipse工程文件。

(不推荐)使用[sbt生成工程文件](https://cwiki.apache.org/confluence/display/SPARK/Contributing+to+Spark#ContributingtoSpark-Eclipse)。这种方式会缺少一些依赖的jar，处理比较麻烦，还不清楚到底是少了啥！

```
$ cd sbt/
$ sed -i 's/^M//g' *
$ cd ..
$ sbt/sbt eclipse -mem 512
```

(推荐)使用MVN编译生成，[使用Maven生成官网文章](http://spark.apache.org/docs/latest/building-with-maven.html)

```
winse@Lenovo-PC ~/git/spark
$ git clean -x -fd #清理非仓库代码

$ echo $SCALA_HOME #指定scala-home
/cygdrive/d/scala

# 这里我直接修改默认值，理论上加 -Phadoop-2.2 选项应该也是可以的
$ vi pom.xml # hadoop.version 2.2.0
$ mvn eclipse:eclipse

$ find . -name ".classpath" | xargs sed -i -e 's/including="\*\*\/\*.java"//' -e 's/excluding="\*\*\/\*.java"//'

#也可以把添加特性的操作/添加scala源码包操作批量处理掉
```

然后导入到eclipse，然后再针对性的处理报错：

* 先把每个工程都**添加scala特性**
* 把含有python源码包的去掉（手动删除.classpath中classpathentry即可）
* 确认下并加上`src/test/scala`的源码包。

注意，进行上面的步骤之前，由于scala源文件比较多，编译的时间会比较长，先把Project->Build Automatically去掉，然后一次性把问题处理掉后再手动build！

* 手动使用`existing maven projects`导入yarn/stable，然后把**yarn/common以链接的形式引入**，并添加到源码包。

![](http://file.bmob.cn/M00/1C/E7/wKhkA1Q7jQ2AMhweAAOC-l-jcz4872.png)

还有一个** value q is not a member of StringContext **[quasiquotes](http://docs.scala-lang.org/overviews/quasiquotes/intro.html)的错误，有些类需要在2.10添加编译组件才能正常编译，修改scala编译首选项。

![](http://file.bmob.cn/M00/1D/07/wKhkA1Q76GyAFNYPAAEYJfk_ZGw816.png)

添加依赖的编译组件后，整个功能就能正常编译通过了。接下来就能调试看源码了。

## Maven编译spark

如果使用的hadoop版本在官网没有集成assembly版本，可以使用maven手动构建。至于打包可以查看下一篇文章。

```
$ export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
$ mvn -Pyarn -Phadoop-2.2 -Dhadoop.version=2.2.0 -DskipTests clean package
```

`yarn`的profile能够可执行的jar文件（包括所有依赖的spark）。

## 小结

断断续续的写了两天，字数统计弄了大半天，主要在于多行注释的处理。时间最主要都消耗在sbt、maven构建eclipse项目文件（生成、fixed）上。编译scala量上去后确实非常非常的慢，不管是maven还是eclipse都慢！

下一篇将使用docker搭建spark环境，并使用远程调试连接到helloworld程序。

## 参考

* [Scala maven builder doesn't understand quasiquotes](http://stackoverflow.com/questions/24800129/scala-maven-builder-doesnt-understand-quasiquotes)
* [Macro Paradise](http://docs.scala-lang.org/overviews/macros/paradise.html)

