---
layout: post
title: "配置ssh登录docker-centos"
date: 2014-09-30 00:10:02 +0800
comments: true
categories: [docker, recommend]
---

上一篇写的是docker的入门知识，并没有进行实战。这些记录下使用ssh登录centos容器。

前文中参考的博客介绍了使用ssh登录tutorial容器（ubuntu），然后进行tomcat的安装，以及通过端口映射在客户机进行访问的例子。

# 尝试

```
docker pull learn/tutorial
docker run -i -t learn/tutorial /bin/bash
	apt-get update
	apt-get install openssh-server
	which sshd
	/usr/sbin/sshd
	mkdir /var/run/sshd
	passwd #输入用户密码，我这里设置为123456，便于SSH客户端登陆使用
	exit #退出
docker ps -l
docker commit 51774a81beb3 learn/tutorial # 提交后，下次启动就可以基于容器更改的系统
docker run -d -p 49154:22 -p 80:8080 learn/tutorial /usr/sbin/sshd -D
ssh root@127.0.0.1 -p 49154
	# 在ubuntu 12.04上安装oracle jdk 7
	apt-get install python-software-properties
	add-apt-repository ppa:webupd8team/java
	apt-get update
	apt-get install -y wget
	apt-get install oracle-java7-installer
	java -version
	# 下载tomcat 7.0.47
	wget http://mirror.bit.edu.cn/apache/tomcat/tomcat-7/v7.0.47/bin/apache-tomcat-7.0.47.tar.gz
	# 解压，运行
	tar xvf apache-tomcat-7.0.47.tar.gz
	cd apache-tomcat-7.0.47
	bin/startup.sh
```

然而在centos上，运行是不成功的。总结操作如下：

```
[root@docker ~]# docker pull centos:centos6
[root@docker ~]# docker run -i -t  centos:centos6 /bin/bash
	yum install which openssh-server openssh-clients

	/usr/sbin/sshd # 这里会报错，需要手动生成key
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key
	ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key

	vi /etc/pam.d/sshd  # 修改pam_loginuid.so为optional
	# /bin/sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd
	
	passwd # 添加密码
```

* 提交保存成果

```
[root@docker ~]# docker ps -l
[root@docker ~]# docker commit 3a7b6994bb2a winse/hadoop # 保存为自己使用的版本

[root@docker ~]# docker run -d winse/hadoop /usr/sbin/sshd
f5cb57f6ec22dd9d257bf610322e2bd547ea0064262fcad63308b932c0490670
[root@docker ~]# docker ps -l
CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS                     PORTS               NAMES
f5cb57f6ec22        winse/hadoop:latest   /usr/sbin/sshd      2 seconds ago       Exited (0) 2 seconds ago                       sharp_rosalind      

[root@docker ~]# docker run -d -p 8888:22 winse/hadoop /usr/sbin/sshd -D
f9814253159373e8a8df3261904200a733b41c63f55708db3cb56a7ebf650cef
[root@docker ~]# docker ps -l
CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS              PORTS                  NAMES
f98142531593        winse/hadoop:latest   /usr/sbin/sshd -D   5 seconds ago       Up 4 seconds        0.0.0.0:8888->22/tcp   boring_bell         
[root@docker ~]# ssh localhost -p 8888
The authenticity of host '[localhost]:8888 ([::1]:8888)' can't be established.
RSA key fingerprint is f5:5e:be:ae:ea:b1:ed:e8:49:43:28:9e:80:87:0d:86.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[localhost]:8888' (RSA) to the list of known hosts.
root@localhost's password: 
Last login: Mon Sep 29 14:48:23 2014 from localhost
-bash-4.1# 
```

参数`-D`表示sshd运行在前台。这样当前的docker容器就会一直有程序在运行，不至于执行完指定的任务就被关闭掉了。

在centos配置ssh登录需要进行额外参数的设置。这个还是挺折腾人的。关于把`/etc/pam.d/sshd`中的`pam_loginuid.so`修改为optional，[stackoverflow]((http://stackoverflow.com/questions/21391142/why-is-it-needed-to-set-pam-loginuid-to-its-optional-value-with-docker))上的回答还是挺中肯的。

连上ssh后，下一步就和你远程操作服务器一样了。其实docker运行一个容器后，就会分配一个ip，你也可以根据这个ip来连接。

```
[root@docker ~]# docker run -t -i winse/hadoop /bin/bash
bash-4.1# ssh localhost
ssh: connect to host localhost port 22: Connection refused
bash-4.1# service sshd start
Starting sshd:                                             [  OK  ]
bash-4.1# ifconfig
eth0      Link encap:Ethernet  HWaddr 1E:2B:23:16:98:7E  
          inet addr:172.17.0.31  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::1c2b:23ff:fe16:987e/64 Scope:Link

# 新开一个终端
[root@docker ~]# ssh 172.17.0.31
The authenticity of host '172.17.0.31 (172.17.0.31)' can't be established.
RSA key fingerprint is f5:5e:be:ae:ea:b1:ed:e8:49:43:28:9e:80:87:0d:86.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.17.0.31' (RSA) to the list of known hosts.
root@172.17.0.31's password: 
Last login: Mon Sep 29 14:48:23 2014 from localhost
-bash-4.1#           
```

## 使用Dockerfile脚本安装

```
[root@docker ~]# mkdir hadoop
[root@docker ~]# cd hadoop/
[root@docker hadoop]# touch Dockerfile
[root@docker hadoop]# vi Dockerfile
	# hadoop2 on docker-centos
	FROM centos:centos6
	MAINTAINER Winse <fuqiuliu2006@qq.com>
	RUN yum install -y which openssh-clients openssh-server #-y表示交互都输入yes

	RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key
	RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key

	RUN echo 'root:hadoop' |chpasswd

	RUN sed -i '/pam_loginuid.so/c session    optional     pam_loginuid.so'  /etc/pam.d/sshd

	EXPOSE 22
	CMD /usr/sbin/sshd -D
	
[root@docker hadoop]# docker build -t="winse/hadoop" .

[root@docker hadoop]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
winse/hadoop        latest              9d7f115ef0ec        5 minutes ago       289.1 MB
...

[root@docker hadoop]# docker run -d --name slaver1 winse/hadoop
[root@docker hadoop]# docker run -d --name slaver2 winse/hadoop
[root@docker hadoop]# docker run -d --name master1 -P --link slaver1:slaver1 --link slaver2:slaver2  winse/hadoop

[root@docker hadoop]# docker restart slaver1 slaver2 master1
slaver1
slaver2
master1

[root@docker hadoop]# docker port master1 22
0.0.0.0:49159
[root@docker hadoop]# ssh localhost -p 49159
... 
-bash-4.1# cat /etc/hosts
172.17.0.31     7ef63f98e2d1
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.17.0.29     slaver1
172.17.0.30     slaver2
```


## 参考

* [Docker学习笔记之一，搭建一个JAVA Tomcat运行环境](http://www.blogjava.net/yongboy/archive/2013/12/12/407498.html)
* [Docker之配置Centos_ssh](http://www.csdn123.com/html/topnews201408/36/1236.htm)
* [pam_loginuid(8) - Linux man page](http://linux.die.net/man/8/pam_loginuid)
* [Why is it needed to set `pam_loginuid` to its `optional` value with docker?](http://stackoverflow.com/questions/21391142/why-is-it-needed-to-set-pam-loginuid-to-its-optional-value-with-docker)