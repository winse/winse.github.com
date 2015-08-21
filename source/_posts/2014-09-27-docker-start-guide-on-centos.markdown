---
layout: post
title: "docker入门"
date: 2014-09-27 20:28:24 +0800
comments: true
categories: [docker]
---

docker进一年来火热，发现挺适合用来做运维系统发布的。如果用来捣鼓hadoop的系统部署感觉还是挺不错的。下面一起来学习下docker吧。

docker中提供了[windows的安装文档](https://docs.docker.com/installation/windows/)，但是其实很坑爹啊。尽管[提供exe安装](https://github.com/boot2docker/windows-installer/releases)，但是最终还是安装visualbox，然后启动带了docker的linux系统（iso）。

如果你已经安装了vmware，但没有安装linux，可以直接[下载iso](https://github.com/boot2docker/boot2docker/releases)，然后通过iso来启动。

## 安装

如果你同时安装了vmware，又已经安装了linux，那下面简单列出安装配置docker中使用的命令。docker需要64位的linux操作系统，我这里使用的是centos6，具体的安装步骤看[官网的安装教程](https://docs.docker.com/installation/centos/)。 

```
[root@docker ~]# yum install epel-release

[root@docker ~]# yum install docker-io
[root@docker ~]# service docker start

[root@docker ~]# docker run learn/tutorial /bin/echo hello world
Unable to find image 'learn/tutorial' locally
Pulling repository learn/tutorial
8dbd9e392a96: Pulling fs layer 
8dbd9e392a96: Download complete 
hello world

[root@docker ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
learn/tutorial      latest              8dbd9e392a96        17 months ago       128 MB
[root@docker ~]# docker images learn/tutorial 
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
learn/tutorial      latest              8dbd9e392a96        17 months ago       128 MB
```

docker执行run命令时，如果指定的image本地不存在，会从[hub服务器](https://registry.hub.docker.com/)获取。也可以先从服务器获取image，然后在执行。

```
docker pull centos
```

【注】：如果启动失败，1：重装一下docker； 2：还是不行，启动报`docker: relocation error: docker: symbol dm_task_get_info_with_deferred_remove, version Base not defined in file libdevmapper.so.1.02 with link time reference`，更新`yum upgrade device-mapper-libs`，然后启动`service docker start`（具体描述见文章末）

## 简单入门

[HelloWorld教程](https://docs.docker.com/userguide/dockerizing/)

#### 单次执行

```
[root@docker ~]# docker run learn/tutorial /bin/echo 'hello world'
hello world
```

命令执行完后，容器就会关闭。

#### 交互式执行方式

```
[root@docker ~]# docker run -t -i learn/tutorial /bin/bash
root@274ede23baad:/# uptime
 12:36:02 up  5:59,  0 users,  load average: 0.00, 0.00, 0.00
root@9db219d2e98b:/# cat /etc/issue
Ubuntu 12.04 LTS \n \l
root@274ede23baad:/# pwd
/
root@274ede23baad:/# ls
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var
root@274ede23baad:/# exit
exit
```

* -t flag assigns a pseudo-tty or terminal inside our new container。
* -i flag allows us to make an interactive connection by grabbing the standard in (STDIN) of the container.


#### 后台任务

```
[root@docker ~]# docker run -d learn/tutorial /bin/sh -c "while true; do echo hello world; sleep 1; done" 
17e28b56e0cc4ddb5522736e2bcfd752d849a5b1d0b598478ee66b255801aa7c

[root@docker ~]# docker ps
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS               NAMES
17e28b56e0cc        learn/tutorial:latest   /bin/sh -c 'while tr   2 minutes ago       Up 2 minutes                            trusting_wozniak    
```

* -d flag tells Docker to run the container and put it in the background, to daemonize it.

执行返回的是containter id(唯一ID)。通过ps可以查看当前的后台任务列表。ps列表中的containter id对应，可以查看相应的信息，最后的字段是一个随机指定的名字（也可以指定，后面再讲）。

```
[root@docker ~]# docker logs trusting_wozniak
hello world
hello world
...

[root@docker ~]# docker stop trusting_wozniak
trusting_wozniak
[root@docker ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

可以通过logs查看容器的标准输出，通过stop来停止容器。

## 深入容器

[Working with Containers](https://docs.docker.com/userguide/usingdocker/)

可以交互式的方式运行container，也可以后台任务的方式运行。

docker的命令：

```
# Usage:  [sudo] docker [flags] [command] [arguments] ..
# Example:
$ sudo docker run -i -t ubuntu /bin/bash
```

每个命令可以指定跟一系列的开关标识(flags)和参数(arguments)。

#### 各种参数

```
$ docker version

$ docker run -d -P training/webapp python app.py

$ docker ps -l
CONTAINER ID  IMAGE                   COMMAND       CREATED        STATUS        PORTS                    NAMES
bc533791f3f5  training/webapp:latest  python app.py 5 seconds ago  Up 2 seconds  0.0.0.0:49155->5000/tcp  nostalgic_morse

# docker run -d -p 6379 -v /home/hadoop/redis-2.8.13:/opt/redis-2.8.13 learn/tutorial /opt/redis-2.8.13/src/redis-server 
be0b410f3601ea36070b3e519d9cc7cbe259caa2392f468c2dd2baebef42c4a8

# docker ps -l
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS                     NAMES
be0b410f3601        learn/tutorial:latest   /opt/redis-2.8.13/sr   10 seconds ago      Up 10 seconds       0.0.0.0:49153->6379/tcp   sad_colden          

# /home/hadoop/redis-2.8.13/src/redis-cli -p 49153
127.0.0.1:49153> keys *
(empty list or set)
127.0.0.1:49153> 
```

* -P flag is new and tells Docker to map any required network ports inside our container to our host. This lets us view our web application.
* -l tells the docker ps command to return the details of the last container started.
* -a the docker ps command only shows information about running containers. If you want to see stopped containers too use the -a flag.
* -p Network port bindings are very configurable in Docker. In our last example the -P flag is a shortcut for -p 5000 that maps port 5000 inside the container to a high port (from the range 49153 to 65535) on the local Docker host. We can also bind Docker containers to specific ports using the -p flag。
* -v flag you can also mount a directory from your own host into a container.

```
[root@docker redis-2.8.13]# docker run -d -p 6379:6379 -v /home/hadoop/redis-2.8.13:/opt/redis-2.8.13 learn/tutorial /opt/redis-2.8.13/src/redis-server 
2c50850c9437698769e54281a9f4154dc4120da2e113802454f1a23c83ab91fe

[root@docker redis-2.8.13]# docker ps
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS                    NAMES
2c50850c9437        learn/tutorial:latest   /opt/redis-2.8.13/sr   29 seconds ago      Up 28 seconds       0.0.0.0:6379->6379/tcp   naughty_yonath  

[root@docker redis-2.8.13]# docker port naughty_yonath 6379
0.0.0.0:6379

[root@docker redis-2.8.13]# docker logs -f naughty_yonath
...
[1] 27 Sep 13:48:12.192 * The server is now ready to accept connections on port 6379
[1] 27 Sep 13:50:33.228 * DB saved on disk
[1] 27 Sep 13:50:43.730 * DB saved on disk
```

* -f This time though we've added a new flag, -f. This causes the docker logs command to act like the tail -f command and watch the container's standard out. We can see here the logs from Flask showing the application running on port 5000 and the access log entries for it.

```
[root@docker redis-2.8.13]# docker top naughty_yonath
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                5015                1433                0                   21:48               ?                   00:00:00            /opt/redis-2.8.13/src/redis-server *:6379
[root@docker redis-2.8.13]# docker inspect naughty_yonath
...
    "Volumes": {
        "/opt/redis-2.8.13": "/home/hadoop/redis-2.8.13"
    },
    "VolumesRW": {
        "/opt/redis-2.8.13": true
    }
}

[root@docker redis-2.8.13]# docker inspect -f '{{.Volumes}}' naughty_yonath
map[/opt/redis-2.8.13:/home/hadoop/redis-2.8.13]

```

#### 重启 

```
[root@docker redis-2.8.13]# docker stop naughty_yonath
naughty_yonath
[root@docker redis-2.8.13]# docker ps -l
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS                     PORTS               NAMES
2c50850c9437        learn/tutorial:latest   /opt/redis-2.8.13/sr   8 minutes ago       Exited (0) 5 seconds ago                       naughty_yonath      
[root@docker redis-2.8.13]# docker start naughty_yonath
naughty_yonath
[root@docker redis-2.8.13]# docker ps -l
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS                    NAMES
2c50850c9437        learn/tutorial:latest   /opt/redis-2.8.13/sr   8 minutes ago       Up 1 seconds        0.0.0.0:6379->6379/tcp   naughty_yonath
```

#### 删除

```
docker stop naughty_yonath
docker rm naughty_yonath
```

## Images

[Working with Docker Images](https://docs.docker.com/userguide/dockerimages/)

#### 列出本地的images

```
docker images
# REPO[:TAG]
docker run -t -i ubuntu:14.04 /bin/bash
docker run -t -i ubuntu:latest /bin/bash
```

#### 从Hub获取镜像Image

```
docker pull centos
docker run -t -i centos /bin/bash
docker search sinatra 
docker pull training/sinatra
```

#### 创建自己的images

直接更新image

```
$ docker run -t -i training/sinatra /bin/bash
root@0b2616b0e5a8:/# gem install json
$ sudo docker commit -m="Added json gem" -a="Kate Smith" \
	0b2616b0e5a8 ouruser/sinatra:v2
$ docker images
$ docker run -t -i ouruser/sinatra:v2 /bin/bash
root@78e82f680994:/#
```

通过DockerFile来添加功能，进行更新。

```
$ mkdir sinatra
$ cd sinatra
$ touch Dockerfile
	# This is a comment
	FROM ubuntu:14.04
	MAINTAINER Kate Smith <ksmith@example.com>
	RUN apt-get update && apt-get install -y ruby ruby-dev
	RUN gem install sinatra

$ docker build -t="ouruser/sinatra:v2" .
$ docker run -t -i ouruser/sinatra:v2 /bin/bash
```

具体的DockerFile中各个指令的含义及其使用方法，参考[Building an image from a Dockerfile](https://docs.docker.com/userguide/dockerimages/)和[Best Practices for Writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/)，以及[Dockerfile Reference](https://docs.docker.com/reference/builder/)。具体例子[docker-perl](https://github.com/perl/docker-perl/blob/r20140922.0/5.020.001-64bit,threaded/Dockerfile)

#### 添加新标签Tag

```
$ docker tag 5db5f8471261 ouruser/sinatra:devel
$ docker images ouruser/sinatra
REPOSITORY          TAG     IMAGE ID      CREATED        VIRTUAL SIZE
ouruser/sinatra     latest  5db5f8471261  11 hours ago   446.7 MB
ouruser/sinatra     devel   5db5f8471261  11 hours ago   446.7 MB
```

#### 上传分享到[hub](https://hub.docker.com/)

```
docker push ouruser/sinatra
```

#### 从本地删除

```
docker rmi training/sinatra
```

## 多container结合使用

[Linking Containers Together](https://docs.docker.com/userguide/dockerlinks/)

#### 端口映射

```
docker run -d -P training/webapp python app.py

docker ps nostalgic_morse
CONTAINER ID  IMAGE                   COMMAND       CREATED        STATUS        PORTS                    NAMES
bc533791f3f5  training/webapp:latest  python app.py 5 seconds ago  Up 2 seconds  0.0.0.0:49155->5000/tcp  nostalgic_morse

docker run -d -p 5000:5000 training/webapp python app.py

docker run -d -p 127.0.0.1:5000:5000 training/webapp python app.py

docker run -d -p 127.0.0.1::5000 training/webapp python app.py

# The -p flag can be used multiple times to configure multiple ports.
docker run -d -p 127.0.0.1:5000:5000/udp training/webapp python app.py

docker port nostalgic_morse 5000
127.0.0.1:49155
```

#### Container Linking

docker想的还是很周到的。面临两个container互相访问，一个db，一个web，哪web怎么访问db的数据呢？

指定container的名称：

```
$ docker run -d -P --name web training/webapp python app.py

$ docker ps -l
CONTAINER ID  IMAGE                  COMMAND        CREATED       STATUS       PORTS                    NAMES
aed84ee21bde  training/webapp:latest python app.py  12 hours ago  Up 2 seconds 0.0.0.0:49154->5000/tcp  web

$ docker inspect -f "{{ .Name }}" aed84ee21bde
/web
```

容器互通：

```
$ docker run -d --name db training/postgres

$ docker rm -f web
$ docker run -d -P --name web --link db:db training/webapp python app.py

$ docker ps
CONTAINER ID  IMAGE                     COMMAND               CREATED             STATUS             PORTS                    NAMES
349169744e49  training/postgres:latest  su postgres -c '/usr  About a minute ago  Up About a minute  5432/tcp                 db, web/db
aed84ee21bde  training/webapp:latest    python app.py         16 hours ago        Up 2 minutes       0.0.0.0:49154->5000/tcp  web
```

链接后，在web容器会添加DB的环境变量，同时把db的ip加入到/etc/hosts中。

```

$ docker run --rm --name web2 --link db:db training/webapp env
    . . .
    DB_NAME=/web2/db
    DB_PORT=tcp://172.17.0.5:5432
    DB_PORT_5432_TCP=tcp://172.17.0.5:5432
    DB_PORT_5432_TCP_PROTO=tcp
    DB_PORT_5432_TCP_PORT=5432
    DB_PORT_5432_TCP_ADDR=172.17.0.5

$ docker run -t -i --rm --link db:db training/webapp /bin/bash
root@aed84ee21bde:/opt/webapp# cat /etc/hosts
172.17.0.7  aed84ee21bde
. . .
172.17.0.5  db    
```

You can see that Docker has created a series of environment variables with useful information about the source db container. Each variable is prefixed with `DB_`, which is populated from the alias you specified above. If the alias were db1, the variables would be prefixed with `DB1_`. 

## 存储

[Managing Data in Containers](https://docs.docker.com/userguide/dockervolumes/)

```
# Adding a data volume
docker run -d -P --name web -v /webapp training/webapp python app.py

# Mount a Host Directory as a Data Volume
docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py
# 只读
docker run -d -P --name web -v /src/webapp:/opt/webapp:ro training/webapp python app.py

# Mount a Host File as a Data Volume
docker run --rm -it -v ~/.bash_history:/.bash_history ubuntu /bin/bash

# Creating and mounting a Data Volume Container
docker run -d -v /dbdata --name dbdata training/postgres echo Data-only container for postgres
docker run -d --volumes-from dbdata --name db1 training/postgres
docker run -d --volumes-from dbdata --name db2 training/postgres
docker run -d --name db3 --volumes-from db1 training/postgres

# Backup, restore, or migrate data volumes
docker run --volumes-from dbdata -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata
docker run -v /dbdata --name dbdata2 ubuntu /bin/bash
docker run --volumes-from dbdata2 -v $(pwd):/backup busybox tar xvf /backup/backup.tar

```

## 回顾

管理docker主要使用其提供的各种命令、以及参数来进行。

* 本地的镜像管理: docker images / docker rmi [image identify]
* 容器管理： docker ps -a|-l / docker start|stop|rm|restart [image identify] 
* 运行容器：docker run [images] [command]
	* -d 后台运行
	* -ti tty交互式运行
	* -P 把容器expose的端口映射到宿主机器端口。可以通过`docker port [container-name]`来查看端口映射关系。
	* -p [host-machine-port:container-machine-port]手动指定端口映射关系
	* -h [hostname] 实例操作系统的hostname
	* --name [name] 容器实例标识
	* -v [path] 建立目录
	* -v [host-machine-path:container-machine-path] 把宿主的文件路径映射到容器操作系统的指定目录
	* --link [container-name:name] 多容器之间互相访问。

还有很多辅助命令如：`top`, `logs`, `port`, `inspect`。以及进行版本管理的`pull`, `push`, `commit`, `tag`等等。

## 更新

* 2015年3月3日00:29:44

docker官网连不上，巨坑！从原来的docker导出

```
[root@docker ~]# docker ps -a
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS                      PORTS               NAMES
4a1ba5605868        learn/tutorial:latest   /bin/bash              15 seconds ago      Exited (0) 11 seconds ago                       loving_wilson        
6e8a77ff8c26        centos:centos6          /bin/bash              10 minutes ago      Exited (0) 10 minutes ago                       determined_almeida  
[root@docker ~]# docker export loving_wilson > learn_tutorial.tar

#===

[root@localhost ~]# cat centos6.tar | docker import - centos:centos6
876f82e7032a2ed567421298c6dd12a74ac7b37fc28ef4fd062ebb4678bd6821
[root@localhost ~]# cat learn_tutorial.tar | docker import - learn/tutorial
dc574b587de3479ecc3622c7b4f12227d894aa1461737612130122092a72bdb4
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED              VIRTUAL SIZE
learn/tutorial      latest              dc574b587de3        23 seconds ago       128.2 MB
centos              centos6             876f82e7032a        About a minute ago   212.7 MB
```

* 2015年8月5日11:04:14

1 看看国内网站是否有对应的镜像： <http://dockerpool.com/downloads>

2 连不上可以<https://registry.hub.docker.com/_/centos/> , 直接到github上面下载对应的[dockerfile](https://github.com/CentOS/sig-cloud-instance-images/tree/CentOS-6/docker)

```
[root@localhost ~]# git clone -b CentOS-6  https://github.com/CentOS/sig-cloud-instance-images.git
[root@localhost docker]# docker build . 

[root@localhost docker]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
<none>              <none>              437c8a32e0c6        27 seconds ago      203.1 MB

# 启动登陆容器，安装sshd
[root@localhost docker]# docker run -ti 437c8a32e0c6 /bin/bash
[root@077cd71ff08f /]# yum install which openssh-server openssh-clients
[root@077cd71ff08f /]# chkconfig --list
iptables        0:off   1:off   2:on    3:on    4:on    5:on    6:off
netconsole      0:off   1:off   2:off   3:off   4:off   5:off   6:off
netfs           0:off   1:off   2:off   3:on    4:on    5:on    6:off
network         0:off   1:off   2:on    3:on    4:on    5:on    6:off
rdisc           0:off   1:off   2:off   3:off   4:off   5:off   6:off
restorecond     0:off   1:off   2:off   3:off   4:off   5:off   6:off
sshd            0:off   1:off   2:on    3:on    4:on    5:on    6:off
udev-post       0:off   1:on    2:on    3:on    4:on    5:on    6:off
[root@077cd71ff08f /]# service sshd status
openssh-daemon is stopped
[root@077cd71ff08f /]# service sshd start
Generating SSH2 RSA host key:                              [  OK  ]
Generating SSH1 RSA host key:                              [  OK  ]
Generating SSH2 DSA host key:                              [  OK  ]
Starting sshd:                                             [  OK  ]
[root@077cd71ff08f /]# vi /etc/ssh/sshd_config 
#UsePAM no
#或者 sed -i '/pam_loginuid.so/c session    optional     pam_loginuid.so'  /etc/pam.d/sshd
[root@077cd71ff08f /]# which sshd
/usr/sbin/sshd
[root@077cd71ff08f /]# passwd 记得添加密码

# 提交更新镜像
[root@localhost ~]# docker ps -a
CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS                      PORTS               NAMES
077cd71ff08f        bigdata:latest        "/bin/bash"         4 minutes ago       Exited (0) 11 seconds ago                       desperate_bell       
7195847a0166        437c8a32e0c6:latest   "/bin/bash"         3 hours ago         Up 5 minutes                                    determined_feynman   
[root@localhost ~]# docker commit 077cd71ff08f bigdata
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
bigdata             latest              c2a336f22ff8        4 minutes ago       261.3 MB

# 启动新容器，使用ssh远程登陆
[root@localhost ~]# docker run -d --dns 172.17.42.1 --name master -h master bigdata /usr/sbin/sshd -D
[root@localhost ~]# docker run -d  --dns 172.17.42.1 --name slaver1 -h slaver1 bigdata /usr/sbin/sshd -D
[root@localhost ~]# docker inspect master
[root@localhost ~]# vi /etc/hosts
[root@localhost ~]# service dnsmasq restart
```

3 [自己制作](http://www.cnblogs.com/2018/p/4633940.html)

```
[root@localhost docker]# wget --no-check-certificate  https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-yum.sh
[root@localhost docker]# chmod +x mkimage-yum.sh
[root@localhost docker]# ./mkimage-yum.sh centos6

```

* 2015年3月2日16:13:12

再在centos6.5上安装最新的，启动后报错：

```
[root@localhost ~]# docker -d
INFO[0000] +job serveapi(unix:///var/run/docker.sock)   
INFO[0000] WARNING: You are running linux kernel version 2.6.32-431.el6.x86_64, which might be unstable running docker. Please upgrade your kernel to 3.8.0. 
INFO[0000] Listening for HTTP on unix (/var/run/docker.sock) 
docker: relocation error: docker: symbol dm_task_get_info_with_deferred_remove, version Base not defined in file libdevmapper.so.1.02 with link time reference
```

需要再安装新的依赖（囧，md，用yum安装还要自己安装其他依赖！！）

```
[root@localhost ~]#  yum install device-mapper-event-libs
```

* 报错2：`cgroup.procs: invalid argument`[2015年8月6日11:11:49]

```
[root@localhost ~]# docker start 5ed45ce5ad3d
Error response from daemon: Cannot start container 5ed45ce5ad3d: [8] System error: write /cgroup/freezer/docker/5ed45ce5ad3d085fe3c004f90eef7c774a722e84cf0c9d18c197cc5900bbc8ae/cgroup.procs: invalid argument
FATA[0000] Error: failed to start one or more containers 
```

修改配置：<http://blog.csdn.net/jollypigclub/article/details/40428095>

```
[root@localhost ~]# vi /etc/sysconfig/docker
...
other_args="--exec-driver=lxc"
#other_args=""
...
```

* docker本地存储的路径[@ 2015年8月5日11:19:17]

```
[root@localhost docker]# cd /var/lib/docker/
[root@localhost docker]# ls
containers  devicemapper  graph  init  linkgraph.db  repositories-devicemapper  tmp  trust  volumes
[root@localhost docker]# cd graph/
[root@localhost graph]# ll
总用量 16
drwx------ 2 root root 4096 8月   5 10:39 d5d33a6a321ae20a3ae4805b5643560ce9c16a49d2f1d32541b39e04ad083983
drwx------ 2 root root 4096 8月   5 10:39 d8ed1be0a39bcc741aa1e95e59b844140d9294afc75082697184cdfbf2bc6a2d
drwx------ 2 root root 4096 8月   5 09:48 f1b10cd842498c23d206ee0cbeaa9de8d2ae09ff3c7af2723a9e337a6965d639
drwx------ 2 root root 4096 8月   5 10:39 _tmp

[root@localhost docker]# cd devicemapper/devicemapper/
[root@localhost devicemapper]# ll
总用量 976024
-rw------- 1 root root 107374182400 8月   5 09:38 data
-rw------- 1 root root   2147483648 8月   5 09:38 metadata
```

## 参考

* [Docker学习笔记之一，搭建一个JAVA Tomcat运行环境](http://www.blogjava.net/yongboy/archive/2013/12/12/407498.html)
* [You are running linux kernel version 2.6.32-431.el6.x86_64(centos 6.5)](http://www.inspires.cn/note/36)
* [Where are Docker images stored?(老版本，也值得一看)](http://blog.thoward37.me/articles/where-are-docker-images-stored/)
* [Docker启动报错 relocation error libdevmapper](http://blog.csdn.net/xu470438000/article/details/43704469)
* [docker镜像与容器存储结构分析](http://www.programfish.com/blog/?p=9)