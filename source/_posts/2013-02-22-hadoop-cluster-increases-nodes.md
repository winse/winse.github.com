---
layout: post
title: "hadoop集群增加节点"
date: 2013-02-22 22:14
comments: true
categories: [hadoop]
---

hadoop的集群的优势，其中之一就是可以灵活的增加数据节点，简简单单的实现扩容！
~~新增个别节点还是可以通过这种方式来运行的，如果是初始化整个集群，一台一台的操作就很纠结了!~~

## 操作步骤

1. 最好安装统一的操作系统。安装的时刻把防火墙关了！
2. 在新节点使用root用户，修改系统的一些参数

	* 修改时间

		```
		date -s 12:00:00
		```

	* 设置IP地址

		```
		vi /etc/sysconfig/network-scripts/ifcfg-eth0
		service network restart
		```

	* 修改host

		```
		vi /etc/sysconfig/network
		## 设置完以后不能立即见效，可以先使用hostname命令生效
		hostname datanode-00003
		```

	* 新增用户hadoop

		```
		useradd hadoop
		passwd hadoop
		```

	* 修改`/etc/hosts`

3. namenode配置文件中添加新datanode

	**切换到namenode节点机器**

	* 如果没有域名解析服务，这里需要用**root用户**来修改namenode的`/etc/hosts`文件，添加新节点的hostname和ip的对应。
	* 拷贝jdk到新节点（最好不要使用系统自带的版本） 。

		```
		scp -r /opt/java/jdk1.6.0_29 datanode-00003:/opt/java
		```

	**然后，从root用户切换到hadoop用户**

	* 修改HADOOP_HOME/conf/slaves文件，添加新节点的hostname（为了以后start/stop **统一管理**hadoop）
	* namenode无密钥登录datanode，执行（为了以后start/stop **统一管理**hadoop）

		```
		ssh-copy-id -i .ssh/id-rsa.pub datanode-00003
		#然后输入新节点hadoop用户的密码即可。
		```

	* 拷贝hadoop程序到新节点。

		```
		rsync -vaz --delete --exclude=logs --exclude=log hadoop-1.0.0 datanode-00003:~/
		```

4. 使用hadoop用户登录到新节点datanode-00003。

	* 修改环境变量。

		```
		cd
		vi .bashrc
		## 添加JAVA_HOME/bin到PATH路径
		# export JAVA_HOME=/opt/java/jdk1.6.0_29
		# export PATH=$JAVA_HOME/bin:$PATH

		source .bashrc
		```
	
	* 创建必要的目录（把hadoop的进程的**pids文件保存的自定义的目录**下，如果放置在tmp下，一段时间过后会被清除）。

		```
		mkdir /opt/cloud
		mkdir /home/hadoop/pids/hadoop/pids
		```
	
5. 启动新节点，加入到集群

	~~有很多文章说使用hadoop-daemon.sh来启动：~~

	``` 
	  $HADOOP/bin/hadoop-daemon.sh start datanode 
	  $HADOOP/hadoop-daemon.sh start tasktracker
	```

	其实，大可不必，使用**hadoop登录到namenode**，在namenode上执行start-all.sh即可：

	```
	bin/start-all.sh
	```

	启动节点的时刻，会检查是否已经启动，**只会启动**未启动的服务。

6. 如果希望节点的数据平均一点，可以执行：

	```
	bin/start-balancer.sh
	```

## 参考资料：

1. [shell脚本自动修改IP信息](http://kerry.blog.51cto.com/172631/517921)
2. http://a280606790.iteye.com/blog/867532
3. http://eclecl1314-163-com.iteye.com/blog/987732
4. http://running.iteye.com/blog/906585

* * * 
[【原文地址】](http://winse.iteye.com/blog/1812689)
