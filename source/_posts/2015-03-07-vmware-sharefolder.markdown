---
layout: post
title: "VMware共享目录"
date: 2015-03-07 22:25:52 +0800
comments: true
categories: [tools]
---

VMware提供了与主机共享目录的功能，可以在虚拟机访问宿主机器的文件。

1. 选择映射目录
	选择[Edit virtual machine settings]，在弹出的对话框中选择[Options]页签，选择[Shared Folders]，点击右边的[Add]按钮添加需要映射(maven)的本地目录。
2. 安装VMware Tools
	* 启动linux虚拟机，选择[VM]菜单，再选择[Install VMware Tools...]菜单。下载完成后，会自动通过cdrom加载到虚拟机。
	* 登录linux虚拟机，执行以下命令：

```
cd /mnt
mkdir cdrom
mount /dev/cdrom cdrom
cd cdrom/
mkdir ~/vmware
tar zxvf VMwareTools-9.2.0-799703.tar.gz -C ~/vmware

cd ~/vmware
cd vmware-tools-distrib/
./vmware-install.pl 
reboot

cd /mnt/hgfs/maven
```

当前的maven目录是映射到宿主的机器目录。

```
[root@localhost maven]# ll -a
total 3
drwxrwxrwx. 1 root root    0 Dec 28  2012 .
dr-xr-xr-x. 1 root root 4192 Mar  7 22:41 ..
drwxrwxrwx. 1 root root    0 Dec 28  2012 .m2
```