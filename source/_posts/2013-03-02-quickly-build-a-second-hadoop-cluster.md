---
layout: post
title: "快速搭建第二个hadoop分布式集群环境"
date: 2013-03-02 00:06
comments: true
categories: [hadoop]
---

万事开头难，第一次搭建集群环境确实是比较难，比较苦恼。但，也不是说第二次搭建集群环境就会容易。

一般，第一次操作我们都会在测试环境中进行，当我们要搭建正式的环境时，是否还要像第一次那样搭建环境呢？
这里提供一种稍稍便捷一点的配置方式来搭建集群，**所有的操作**都在**namenode**上面进行！

192.168.3.100 h100为测试环境的namenode。

将要搭建的环境包括3台机器，已经全部安装好redhat的操作系统：

```
192.168.80.81 h81 #namenode
192.168.80.82 h82 #datanode1
192.168.80.83 h83 #datanode2
```

使用SecureCRT工具，root用户登录到新环境namenode。步骤参考，有些步骤需要输入密码(**可以通过expect来模拟**)，不能一次性全部执行。

```
## 生成root用户的密钥对
ssh-keygen 

## 建立到100机器的无密钥登录
ssh-copy-id -i .ssh/id_rsa.pub hadoop@192.168.3.100

## 拷贝JDK，将加入hadoop用户的环境变量
mkdir -p /opt/java
scp -r hadoop@192.168.3.100:/opt/java/jdk1.6.0_29 /opt/java

## 把集群的IP和机器名对应加入hosts文件
vi /etc/hosts

# 192.168.80.81 h81
# 192.168.80.82 h82
# 192.168.80.83 h83

## 定义常量
namenode='h81'
hosts=`cat /etc/hosts | grep 192.168 | awk '{print $2}'`

## 修改时间，~~可以日期和时间一起修改的~~
DATE='2013-03-01'
TIME='10:30:00'

for host in $hosts
do
	ssh $host date -s $DATE
	ssh $host date -s $TIME
done

## 建立namenode到datanodes的无密钥访问，这里需要输入对应datanode的root用户的密码
for host in $hosts
do
	ssh-copy-id -i .ssh/id_rsa.pub $host
done

#### 
for host in $hosts
do
	## 在集群所有节点上创建hadoop用户，会提示很多次输入密码。可以通过修改/etc/shadow替换密码输入的步骤
	ssh $host useradd hadoop
	ssh $host passwd hadoop

	## 拷贝jdk到datanodes
	if [ $host != $namenode ]
	then
		scp /etc/hosts $host:/etc/hosts
		ssh $host mkdir -p /opt/java
		scp -r /opt/java/jdk1.6.0_29 $host:/opt/java 2>&1 > jdk.scp.$host.log & 
	fi

	## 修改集群的hostname主机名称
	ssh $host hostname $host
	ssh $host cat /etc/sysconfig/network | sed s/localhost.localdomain/$host/g > /tmp/network && cat /tmp/network > /etc/sysconfig/network

	## 创建数据目录，并把权限分配给hadoop
	ssh $host mkdir /opt/cloud
	ssh $host chown hadoop /opt/cloud

done

## ！切换到hadoop用户
su - hadoop

## 生成hadoop用户的密钥对
ssh-keygen

## 在hadoop用户的终端定义变量（root的终端变量获取不到的）
namenode='h81'
hosts=`cat /etc/hosts | grep 192.168 | awk '{print $2}'`

## 使namenode的hadoop用户无密钥登录到集群各个机器
for host in $hosts
do
	ssh-copy-id -i .ssh/id_rsa.pub $host
done

## 更新hadoop用户的环境变量，
vi .bashrc

# export JAVA_HOME=/opt/java/jdk1.6.0_29
# PATH=$JAVA_HOME/bin:/usr/sbin:$PATH
# export PATH

## 修改datanodes的环境环境变量，同时为集群创建必要的目录
for host in $hosts
do
	if [ $host != $namenode ]
	then
		scp .bashrc $host:~/.bashrc
	fi

	ssh $host source .bashrc
	ssh $host mkdir -p /home/hadoop/cloud/zookeeper
	ssh $host mkdir -p /home/hadoop/pids/katta/pids
	ssh $host mkdir -p /home/hadoop/pids/hadoop/pids 

done

## 建立namenode下的hadoop用户到192.168.3.100的无密钥访问
ssh-copy-id -i .ssh/id_rsa.pub 192.168.3.100

## 从100上拷贝集群程序
rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/lucene ~/
rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/sqoop-1.4.1 ~/
rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/zookeeper-3.3.5 ~/

rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/hadoop-1.0.0 ~/
rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/hbase-0.92.1 ~/
rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/katta-core-0.6.4 ~/
rsync -vaz --delete  --exclude=logs --exclude=log  192.168.3.100:~/lucene-shared-lib ~/

## 查找配置文件中与测试环境有关的信息
[hadoop@h81 ~]$ find */conf | while read conf; do if grep -E 'h100|192.168.3.100' $conf > /dev/null; then echo $conf;fi;done
hadoop-1.0.0/conf/mapred-site.xml
hadoop-1.0.0/conf/core-site.xml
hadoop-1.0.0/conf/masters
hbase-0.92.1/conf/hbase-site.xml
katta-core-0.6.4/conf/katta.zk.properties
katta-core-0.6.4/conf/masters
lucene/conf/config-env.sh
[hadoop@h81 ~]$ 

## 替换为新的nameode的hostname
find */conf | while read conf; do if grep -E 'h100|192.168.3.100' $conf > /dev/null; then  cat $conf | sed s/h100/h81/g > /tmp/conf && cat /tmp/conf > $conf ;fi;done

## 修改其他配置
vi hadoop-1.0.0/conf/slaves
vi hbase-0.92.1/conf/regionservers
vi katta-core-0.6.4/conf/nodes

## 确认是否还有原有集群的余孽！
find */conf | while read conf; do if grep -E 'h10' $conf > /dev/null; then echo $conf;fi;done

## 拷贝集群程序到datanodes
for host in $hosts
do
	if [ $host != $namenode ]
	then
		rsync -vaz --delete  --exclude=logs --exclude=log  ~/hadoop-1.0.0 $host:~/ &
		rsync -vaz --delete  --exclude=logs --exclude=log  ~/hbase-0.92.1 $host:~/ &
		rsync -vaz --delete  --exclude=logs --exclude=log  ~/katta-core-0.6.4 $host:~/ &
		rsync -vaz --delete  --exclude=logs --exclude=log  ~/lucene-shared-lib $host:~/ &
	fi
done
```

**如果你觉得sed修改麻烦，要备份，在写回！其实有`sed -i`（--in-place）参数提供了直接写入的功能。**

在批处理文件内容替换时，使用到了临时文件，当然也可以先把文件备份后，再写入新文件中，如下面的方式。
但，先备份再写入新文件 有个缺陷就是原始文件的权限会丢失！

```
ssh $host \
mv /etc/sysconfig/network /etc/sysconfig/network.back && \ 
cat /etc/sysconfig/network.back | sed s/localhost.localdomain/$host/g > /etc/sysconfig/network
```

最后你懂的：

```
 hadoop-1.0.0/bin/hadoop namenode -format
 hadoop-1.0.0/bin/start-all.sh
```

通过for，scp， ssh， sed， awk，rsync，vi， find，ssh-copy-id， mkdir等命令仅在namenode上完成集群的部署工作。

仅新增节点，又不想修改namenode配置文件！可以用下面的方法启动新节点：

```
[hadoop@h101 ~]$ hadoop-1.0.0/bin/hadoop-daemon.sh start datanode

starting datanode, logging to /home/hadoop/hadoop-1.0.0/libexec/../logs/hadoop-hadoop-datanode-h101.out

[hadoop@h101 ~]$ hadoop-1.0.0/bin/hadoop-daemon.sh start tasktracker

starting tasktracker, logging to /home/hadoop/hadoop-1.0.0/libexec/../logs/hadoop-hadoop-tasktracker-h101.out
```


* * * 
[【原文地址】](http://winse.iteye.com/blog/1820209)
