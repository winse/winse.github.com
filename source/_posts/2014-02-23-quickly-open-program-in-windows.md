---
layout: post
title: "[Windows运行]快速打开程序"
date: 2014-02-23 20-09
comments: true
categories: [tools]
---

由于种种原因，一直都在Windows下进行编程。如eclipse/Office/QQ/...的软件拖住了切换平台的决心！

在使用windows的同时，形成了一些自己的习惯。使用`WIN + r`来快速打开应用，如regedit/notepad/mspaint/magnify/cmd等。

希望能直接运行Git Shell/Cygwin Terminal这些在**开始**中的菜单。但，在**运行**窗口直接输入的命令都得在PATH所在的路径下。如果把路径全部加入到PATH又没有这个必要，并且命令都是以lnk的快捷方式存储。

```
C:\Users\Administrator\AppData\Local\GitHub\GitHub.appref-ms --open-shell

C:\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -

"C:\Program Files\Vim\vim74\vim.exe"
"C:\Program Files\Vim\vim74\gvim.exe"

```

在已经打开命令行窗口情况下，可以通过定义alias（别名）来实现。具体请[参考](http://blog.sina.com.cn/s/blog_9bf4cb690101byho.html)。

```
C:\Users\Administrator>doskey cygwin=C:\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -

C:\Users\Administrator>doskey /MACROS
cygwin=C:\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -

C:\Users\Administrator>cygwin

```

通过别名可以简化命令，但是必须在已经打开命令行窗口的情况下！！

**解决办法：**
最后妥协了，定义一个路径`D:\local\bin`，加入到*PATH*环境变量。把需要使用通过**运行**打开的程序在*bin*目录下建立一个快键指向。使用mklink是一个软链接。（当然也可以创建个快捷方式，然后改名称）

```
D:\local\bin>mklink git.lnk "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\GitHub, Inc\Git Shell.lnk"

D:\local\bin>mklink cygwin.lnk "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cygwin\Cygwin Terminal.lnk"

D:\local\bin>mklink vim.lnk "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Vim 7.4\Vim.lnk"

```

建立指向后的效果如下：

```
D:\local\bin>dir
 驱动器 D 中的卷是 Software
 卷的序列号是 C83F-14A7

 D:\local\bin 的目录

2014/02/01  01:57    <DIR>          .
2014/02/01  01:57    <DIR>          ..
2014/02/01  01:56    <SYMLINK>      cygwin.lnk [C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cygwin\Cygwin Terminal.lnk]
2014/02/01  01:55    <SYMLINK>      git.lnk [C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\GitHub, Inc\Git Shell.lnk]
2014/02/01  01:57    <SYMLINK>      vim.lnk [C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Vim 7.4\Vim.lnk]
               3 个文件              0 字节
               2 个目录  9,673,441,280 可用字节

```

按照上面的操作[解决办法]，就可以通过`WIN + r`然后输入`git`打开*Git Shell*。

本文所处理的问题，在Windows下有**现成的工具**[Launcher](http://www.launchy.net/)可以查找指定路径下的所有程序/文档。

## 其他快键

通过`WIN + ↑`可以最大化当前窗口。

## 参考

*   [最绿色最高效，用win+r启动常用程序和文档](http://xbeta.info/win-run.htm)

* * * 
[【原文地址】](http://winseliu.logdown.com/posts/2014/02/23/quickly-open-program-in-windows)
