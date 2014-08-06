---
layout: post
title: "top命令使用"
time: 2013-02-26 01:07
comments: true
categories: [shell]
---

使用过linux的系统的人，应该都用过top命令。
top集成了系统的许多功能，可以查看时间，查看系统的负载，查看cpu和mem的使用情况，查看系统运行的程序等。

top命令显示界面可以分成3部分：

* 系统总体性能（Summary_Area）
* 命令输入光标（Message/Prompt line）
* 任务显示区（Columns Header，Task Area）

## 常用的命令

* [ q ] ，或 [ ctrl + c ]      退出top命令。
* [ h ] ，或 [ ? ]             查看帮助，然后可以按ESC回到top界面。

## 在Top输出界面显示CPU内核数量 - [ 1 ]（数字1）

top命令默认在一行中显示所有CPUs。

![](http://dl.iteye.com/upload/attachment/0080/8394/c2b927b9-9f56-39c7-82a7-9842d7096443.png)

可以在该交互界面输入 [ 1 ] （数字1），显示当前系统的cpu数量，以及cpus的使用情况。如下图所示。

![](http://dl.iteye.com/upload/attachment/0080/8396/1544352d-9368-3444-a89b-fa9752417fbc.png)

## 刷新Top命令界面

手动刷新可以通过 [ space ] 和 [ enter ] 键来执行。

如果需要修改刷新频率，可以通过命令 [ d ] 或 [ s ] ，然后再输入数字（新的时间），最后键入 [ enter ] 使设置生效。

![](http://dl.iteye.com/upload/attachment/0080/8401/69556fcc-3ba9-3ea6-8ca5-525dc139e0a3.png)

## 高亮运行中的进程 - [ b / x / y ]

输入命令 [ b ] 能开启高亮显示，这个是行列高亮的总开关。(在SSH远程登录时可能需要先输入命令 [ B ] 启动高亮才行)
高亮的行表示运行中的程序，高亮的列为当前数据排序列。

如果还需要对行或列进行控制，可以输入 [ y ] 或 [ x ] 来执行。

![](http://dl.iteye.com/upload/attachment/0080/8405/28d64d90-d2ea-3e4a-ae3b-dc02dc824bf1.png)

还有 [ z ] 命令能改变颜色，但是在远程登录的情况下不起作用。

## 显示详细命令和参数- [ c ]

输入[c] 用来显示 命令路径和其传递的参数。

![](http://dl.iteye.com/upload/attachment/0080/8407/e0df5c72-a96d-38d7-97be-8fc09bc9b574.png)

## 修改排序字段

通过命令 [ M ] 把Task_Area的**排序列**切换到%MEM列， [ N ] 切换为PID， [ P ] 切换到%CPU， [ T ] 切换到Time+。

如果你觉得这些不能满足你，那，你就的自定义。通过 [ F ] / [ O ] （大写的o字母）来选择需要排序的列。小写的 f 和 o 用来选择需要显示的列。
键入 [ F ] 后，会显示所有字段。输入需要排序列前面的字母标识，然后回车即可。

![](http://dl.iteye.com/upload/attachment/0080/8412/1d0f445e-b6ae-3f08-a3de-df1f76e73d7a.png)

在交互界面，可以通过 [ R ] 命令来反转排序。在界面显示的列中还可以通过 [ < ] / [ > ] 直接切换排序列。

## 把Top输出切分成多个窗口- [ A ]

按 [ A ] 后，会显示4个分屏的窗口，使用 [ a ] / [ w ] 可以切换4种状态作为当前状态，然后再按 [ A ] 可使当前状态全屏。

![](http://dl.iteye.com/upload/attachment/0080/8416/3a62f8c2-50d4-3305-89b1-42e009bb05d5.png)

也可以通过输入 [ G ] 命令，再使用数字选择对应的状态即可。

![](http://dl.iteye.com/upload/attachment/0080/8418/bb906d0f-d4bd-319e-9b22-529114628caf.png)

## 显示Summary区域的信息

本来写的是隐藏的，但是作为监控来说，为啥隐藏这些有用的信息呢？
但是，如果默认未显示，可以使用下列的命令显示。

![](http://dl.iteye.com/upload/attachment/0080/8410/89c2c42a-67fd-31da-ae65-860958a0ec3d.png)

* 键入命令 [ l ]（字母L的小写） - 显示/隐藏 系统负载，对应上图的第1行。
* 键入命令 [ t ] - 显示/隐藏 CPU的状态，对应第2，3行。
* 键入命令 [ m ] - 显示/隐藏 内存信息，对应第4，5行。

## 其他不常用的命令

* 一般使用top都是一起交互方式使用，使用命令行参数 [ -b ] ，可以以类似日志方式（追加）来保存当前系统的运行状态。
* 如果希望把配置保存起来，作为下次的默认配置，可以使用 [ W ]
* 使用 [ -u ] / [ u ] / [ p ]来控制监控特定的进程/用户。
* 使用 [ r ] 来修改程序的优先级别（nice值）
* 使用 [ k ] 关闭特定pid的程序。

## 参考资料：

* [Can You Top This? 15 Practical Linux Top Command Examples](http://www.thegeekstuff.com/2010/01/15-practical-unix-linux-top-command-examples/)
* [top具体参数说明](http://os.51cto.com/art/201108/285581.htm)
* [linux命令详解](http://bbs.linuxtone.org/thread-1684-1-1.html)（很棒）
* <http://tolywang.itpub.net/post/48/130884>
* <http://blog.csdn.net/aten_xie/article/details/6564599>


* * * 
[【原文地址】](http://winse.iteye.com/blog/1814999)
