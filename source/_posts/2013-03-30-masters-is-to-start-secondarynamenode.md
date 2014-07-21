---
layout: post
title: "masters配置是用来启动hadoop1 secondarynamenode"
date: 2013-03-30 12-43
comments: true
categories: [hadoop]
---

>
>hadoop2中已经不使用masters来启动secondnamenode了！
>`SECONDARY_NAMENODES=$($HADOOP_PREFIX/bin/hdfs getconf -secondarynamenodes 2>/dev/null | sed 's/^M//g' )`
>

- - - - -

http://blog.csdn.net/dajuezhao/article/details/5987580 写道

>2、secondarynamenode一般来说不应该和namenode在一起，所以，我把它配置到了datanode上。配置到datanode上，一般来说需要改以下配置文件。conf/master、conf/hdfs-site.xml和conf/core-site.xml这3个配置文件，修改部分如下:	
master：一般的安装手册都是说写上namenode机器的IP或是名称。这里要说明一下，这个master不决定哪个是namenode，而决定的是secondarynamenode（决定谁是namenode的关键配置是core-site.xml中的fs.default.name这个参数）。 

《SecondaryNamenode应用摘记 http://blog.csdn.net/dajuezhao/article/details/5987580》

今天看hadoop/bin目录下的shell时，发现start-dfs.sh中有如下的命令：

```
"$bin"/hadoop-daemon.sh --config $HADOOP_CONF_DIR start namenode $nameStartOpt
"$bin"/hadoop-daemons.sh --config $HADOOP_CONF_DIR start datanode $dataStartOpt
"$bin"/hadoop-daemons.sh --config $HADOOP_CONF_DIR --hosts masters start secondarynamenode
```

![](http://file.bmob.cn/M00/03/DE/wKhkA1PMcNyAaz78AACVrXwbfzc895.png)

也就是，使用start-dfs.sh时，是启动**该机器**的namenode服务，**masters**指定的secondarynamenode服务！
正如最上面引用中说的一样！

其实masters和slaves文件中定义的内容，就是用于shell来启动对应机器的服务的！！
如果你自己管理他们，压根不需要这些文件！

```
$ find . -type f | while read file;do  if cat $file | grep -E "masters|slaves" | grep -v "^#" ; then echo "=== $file"; echo "" ; fi;  done
....
    export HOSTLIST="${HADOOP_CONF_DIR}/slaves"
=== ./slaves.sh

"$bin"/hadoop-daemons.sh --config $HADOOP_CONF_DIR --hosts masters start secondarynamenode
=== ./start-dfs.sh

"$bin"/hadoop-daemons.sh --config $HADOOP_CONF_DIR --hosts masters stop secondarynamenode
=== ./stop-dfs.sh
```
  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1839126)
