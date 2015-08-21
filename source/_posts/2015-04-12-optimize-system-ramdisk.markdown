---
layout: post
title: "使用RamDisk来优化系统"
date: 2015-04-12 16:56:09 +0800
comments: true
categories: [tools]
---

最近加了一条8G的内存，总共16G。暂时来说很难全部用起来。如果能够实现类似linux的shm分区的话，那就完美了，把临时的数据全部放到这个内存分区中。最好是免费的，通过一阵折腾搜索，整理如下：

去到官网<http://www.ltr-data.se/opencode.html/#ImDisk>直接下载`ImDisk Toolkit`<http://reboot.pro/files/file/284-imdisk-toolkit/>，toolkit里面已经集成了ImDisk软件。（新版本的toolkit可以节省很多事情，参考最后的两个链接看看即可）

配置：填写大小`5`、盘符`S`、磁盘格式`NTFS`，然后点击【确定】格式化磁盘，然后就可以使用了。

![](/images/blogs/ramdisk-config.png)

把临时的文件目录指定到ramdisk，重启系统。

![](/images/blogs/ramdisk-temp.png)

上面仅仅是把用户和系统的临时目录移到**内存盘**中。由于rar，java一些软件都是用用户的临时目录，已经可以体验到加速的快感了！！直接拖拽解压rar情况下速度明显快了很多。

{% comment %}
多数情况工作还是以浏览查看网页，把浏览器的缓冲放到内存，既能去掉磁盘无用的一次性读写，还能加快速度！

我使用的是chrome，默认缓冲放置在`C:\Users\winse\AppData\Local\Google\Chrome\User Data\Default\Cache`，网上有用添加启动参数的方式，最终解决还要修改注册表比较麻烦。这里使用文件链接的方式，把Cache目录重定向到内存盘。

```
rmdir "C:\Users\winse\AppData\Local\Google\Chrome\User Data\Default\Cache" #删掉原来的Cache目录
mkdir S:\Temp\Chrome\Cache
mklink /J "C:\Users\winse\AppData\Local\Google\Chrome\User Data\Default\Cache" S:\Temp\Chrome\Cache
```
{% endcomment %}

还有一个问题，重启后，内存盘的数据会被全部清掉。默认情况下只建立了Temp目录，没有我们指定的Cache目录。Chrome启动的时刻如果发现Cache目录为不可用状态会重建该目录。

在Advanced页签，**Load Content from Image File or Folder**选项可以选择初始化加载的内容。我们只要先把目录结构建立后，然后在初始化后加载该路径一切都解决了。

```
E:\local\home\RamDiskInit>find .
.
./Temp
./Temp/Chrome
./Temp/Chrome/Cache
```

然后在`RamDisk Config`的Advanced页签选择**E:\local\home\RamDiskInit**作为**Load Content**即可。

## 参考

* <http://zohead.com/archives/rsync-performance-linux-cygwin-msys/> 从这里看到ramdisk-imdisk
* <http://www.appinn.com/imdisk/> 安装简单使用，以及两篇核心文章的链接
* <http://www.ltr-data.se/opencode.html/#ImDisk>
* [超小巧效能强悍的穷人版 Ramdisk－ImDisk (设定篇) ](http://www.kenming.idv.tw/super_lighweight_ramdisk_imdisk_setup#more-1995) 
* [Win7 x64 下使用 ImDisk 当作RamDisk的小小心得与改良方法](http://www.mobile01.com/topicdetail.php?f=300&t=2200352)