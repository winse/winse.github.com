---
layout: post
title: "scala shell #! 惊叹号井号"
date: 2014-09-03 12:55:32 +0800
comments: true
categories: [scala, shell]
---

工作中主要是写java代码，shell也只是用于交互性操作，写脚本的次数比较少。对于`#!`**井号叹号**仅仅是教条式的添加在脚本开头，并且基本上都是`#!/bin/sh`。

今天在看scala官方的[入门教程](http://www.scala-lang.org/documentation/getting-started.html)尽然发现`!#`的写法，很是困惑，Google查询也不知道怎么描述关键字，一般搜索引擎都把这些操作符过滤掉了的。

```
#!/bin/sh
exec scala "$0" "$@"
!#
object HelloWorld extends App {
  println("Hello, world!")
}
HelloWorld.main(args)
```

首先了解下`#!`作用：如果`#!`在脚本的最开始，脚本程序会把第一行的剩余部分当做解析器指令；使用当前的解析器来执行程序，同时把当前脚本的路径作为参数传递给解析器。

> In computing, a shebang is the character sequence consisting of the characters number sign and exclamation mark (that is, "#!") at the beginning of a script.
>
> Under Unix-like operating systems, when a script with a shebang is run as a program, the program loader parses the rest of the script's initial line as an interpreter directive; the specified interpreter program is run instead, passing to it as an argument the path that was initially used when attempting to run the script.

如果把`!#`去掉，再执行上面的脚本则会报错：**error: script file does not close its header with !# or ::!#**，查寻一番后，这原来是Scala的脚本功能的内部处理。通过SourceFile.scala关键字搜索到了[该文](http://www.cnblogs.com/agateriver/archive/2010/09/07/scala_pound_bang.html)列出了具体的位置，还有[A Scala shell script example](http://alvinalexander.com/scala/scala-shell-script-example-exec-syntax)和我有同样疑问。

![](http://file.bmob.cn/M00/0B/B1/wKhkA1QGuE-AP-ihAAA1mwvYd5E865.png)

可以在《Programing in Scala -- A comprehensive step-by-step guide》一书的附录A中 Scala scripts on Unix and Windows 查找到相应的描述：把`#!`和`!#`之间的内容忽略掉了。

语法糖的疑惑解决了，针对上面的脚本还有个问题：exec执行完了，下面的内容不执行了？在exec命令的前面打上调试语句，也只输出了**sh start**。

```
winse@Lenovo-PC ~
$ cat script.scala
#!/bin/sh
echo 'sh start'
exec scala "$0" "$@"
echo 'sh end'
!#
object HelloWorld extends App {
    print("hello world")
}

HelloWorld.main(args)

winse@Lenovo-PC ~
$ sh script.scala
sh start
hello world

```

> exec 使用 exec 方式运行script时, 它和 source 一样, 也是让 script 在当前process内执行, 但是 process 内的原代码剩下部分将被终止. 同样, process 内的环境随script 改变而改变.

所以，整个脚本流程就是：执行shell，调用exec来调用scala的解释器执行整个脚本内容，而解释器会过滤掉`#!`和`!#`之间内容，执行完后，exec退出脚本，实现scala脚本执行的功能。这样折中的使用方式，应该是为了处理**参数传递***的问题！

## 参考

* [井号加叹号的作用是什么](http://bbs.chinaunix.net/thread-3583927-1-1.html)
* [Shebang (Unix)](http://en.wikipedia.org/wiki/Shebang_%28Unix%29)
* [shell 十三問? ](http://bbs.chinaunix.net/thread-218853-1-1.html)
* [Scala 脚本的 pound bang 魔术](http://www.cnblogs.com/agateriver/archive/2010/09/07/scala_pound_bang.html)
* [A Scala shell script example (and discussion)](http://alvinalexander.com/scala/scala-shell-script-example-exec-syntax)
* [Advanced Bash-Scripting Guide An in-depth exploration of the art of shell scripting](http://tldp.org/LDP/abs/html/abs-guide.html)
* [linux中fork, source和exec的区别 ](http://blog.chinaunix.net/uid-27653755-id-4385938.html)
* [exec](http://ss64.com/bash/exec.html)