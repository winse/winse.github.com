---
layout: post
title: "Win7下安装Fedora（linux）"
date: 2011-02-28 18:26
comments: true
categories: [tools]
---

（用虚拟接vmware安装，就不说了，这个相对来说没有心理压力。如果没装好，删掉就可以了。）

看了一个视频，热血沸腾的要转Linux，准备了老半天。

## 资料准备

1、查了一些资料，有硬盘安装安装Fedora，同时使用EasyBCD做多系统的启动(Win7下Fedora14硬盘或U盘安装指南[http://www.linuxidc.com/Linux/2010-12/30459.htm](http://www.linuxidc.com/Linux/2010-12/30459.htm))。

比较麻烦，手边也有空白光盘。

2、下载了fedora [http://fedoraproject.org/zh_CN/get-fedora-options](http://fedoraproject.org/zh_CN/get-fedora-options)

刻录到光盘（最好不要用可擦写的刻；可擦写刻录的，老半天都进不去）

## 安装（多个硬盘也可以使用这个方法，不过更简单）

**1）磁盘准备**

在安装Fedora之前，最好先把要用的Linux磁盘分区准备好。

注意：**Linux可以安装到逻辑分区的**。硬盘**一般**可分四个主分区和一个拓展分区，由于没有注意到这个限制，在swap分区的时刻搞了好长的时间。可以把Linux安装分区全部放到拓展分区内的**逻辑分区**，这样就不会受到分区个数的影响。
同时方便以后修改和删除等操作，**建议**把linux（临时的系统）的**硬盘空间的后面**，方便以后回收和合并。

下图为安装为后的分区情况：

![](http://dl.iteye.com/upload/attachment/426741/0e52a30c-4a49-3d88-aa7d-3d267e350de4.jpg)

① 无效19.7G为为linux的"/"root路径	
② 1.9G为Linux Swap缓冲分区

**2）安装Linux系统**

进入Fedora的live系统后，点击安装到硬盘的图标（Install to Hard Disk）。安装过程和其他的Win7系统的安装类似，有图形界面。

注意：选择启动引导信息的安装位置，这里选择安装Fedora的分区。好处就是不会干扰到原有的Win7系统。

① 在“Install boot loader on /dev/sda”选项的时刻，选择“Change device”。 	
② 在弹出的“Boot loader device”对话框中选择“First sector of boot partition - /dev/sda4”（/dev/sda4为我安装Fedora的主分区）

![](http://dl.iteye.com/upload/attachment/426552/c4d299d6-b5ab-3b69-849a-306c97d884c6.png)

**3）修改启动设置**

安装完成重启之后，就会进入到Win7，根本不会有选择进入Fedora提示。这就说明安装的Fedora对于原来的Win7系统没有任何的影响。

① 下面安装grub工具来进行多系统的启动管理EasyBCD。

开机程序很好用的小工具:EasyBCD  [下载安装](http://www.linuxidc.com/Linux/2007-12/10060.htm)

② 设置启动项（[http://hi.baidu.com/rebornlinlin/blog/item/43dd70ce10bc8a29f9dc6114.html](http://hi.baidu.com/rebornlinlin/blog/item/43dd70ce10bc8a29f9dc6114.html)）

以下两种方式都是可以的。

![](http://dl.iteye.com/upload/attachment/426763/f7ca6a64-93b4-386a-b569-3acb1ceea6b5.jpg)

![](http://dl.iteye.com/upload/attachment/426765/ed926b24-9dc6-3592-b795-b0418bf8ade2.jpg)

## Fedora的sudo配置修改

在执行一些特权名命令的时刻，sudo命令总是的提示输入密码，很烦。（[http://www.linuxidc.com/Linux/2010-12/30460.htm](http://www.linuxidc.com/Linux/2010-12/30460.htm)）

打开终端Terminal输入:

```
su -
```

提示输入root用户密码。输入完root密码后<Enter>回车，即可获得root权限。

再执行:

```
visudo
```

将会打开/etc/sudoers配置文件，找到

```
root ALL=(ALL) ## ALL这一行,紧跟此行增加一行
winse ALL=(ALL)  NOPASSWD:ALL
```

登陆后可以使用sudo，且不用再次输入密码。

  

* * * 
[【原文地址】](http://winse.iteye.com/blog/934850)
