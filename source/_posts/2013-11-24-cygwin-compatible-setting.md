---
layout: post
title: "cygwin兼容配置"
date: 2013-11-24 20:20
comments: true
categories: [tools]
---

换了新电脑后，以及hadoop2/hbase/zookeeper都提供了基于windows的命令。使用cygwin的驱动力弱化了。现在主要用于git/jekyll/sed/awk/find等基础工具的使用。同时多窗口运行需求比较少。当前主要使用自带的mintty。

## .vimrc

默认Vim的insert模式下使用上下方向键使用会变成其他的输入(方向键变成ABCD)，操作很麻烦。需要对vim进行一些设置。

```
	Winseliu@WINSE ~
	$ cat .vimrc 
	set nocompatible 
	set backspace=indent,eol,start 
	set bs=2 
```

**参考** ： <http://ruby-china.org/topics/4866> 第19楼的回复

## /etc/fstab 文件权限

```
	none /cygdrive cygdrive binary,noacl,posix=0,user 0 0	
```

## 打开windows窗口

```
	explorer '/select,' "$(cygpath -C ANSI -w "$XPATH")"
```

**参考** ： <http://oldratlee.com/post/2012-12-22/stunning-cygwin>

## SecureCRT

## java查找文件路径

```
	Winseliu@WINSE /cygdrive/d/winsegit
	$ antlr4
	Error: Unable to access jarfile /cygdrive/d/winsegit/lib/antlr-4.1-complete.jar
```

由于java在window环境下需要的路径是c:\，需要通过cygpath进行转换。

```
	alias antlr4='java -jar `cygpath -w $WINSE_HOME/lib/antlr-*-complete.jar`'
	export CLASSPATH=".;`cygpath -w $WINSE_HOME/lib/antlr-*-complete.jar`;$CLASSPATH"
```

## 字符集

Linux和window不同，Linux默认的字符集是UTF8，而Windows为GBK。
为了统一两个环境的字符，需要对Cygwin的字符集进行设置。

``` 
	#.bashrc
	export LANG="zh_CN.GB2312"
	export OUTPUT_CHARSET="GB2312"
```
	
还需要把连接工具的编码也改成gb2312。

**参考** ： <http://www.cygwin.cn/site/info/show.php?IID=1006>

## 参考 

* <http://stackoverflow.com/questions/13427288/cygdrive-prefix-does-not-work-in-bash-script>
* <http://www.cygwin.com/ml/cygwin/2008-01/msg00095.html>

