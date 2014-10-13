---
layout: post
title: "Expect-批量实现SSH无密钥登录"
date: 2014-09-07 16:11:18 +0800
comments: true
categories: [shell, tools]
---

在安装部署Hadoop集群的首要步骤就是配置SSH的无密钥登陆。

```
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

ssh-copy-id -i ~/.ssh/id_rsa.pub root@$ip
```

然后，可以通过ssh命令来进行批量的操作。

```
ssh root@$ip 'cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys'
scp -o StrictHostKeyChecking=no /etc/hosts root@${ip}:/etc/
```

但是，一些需要密码的dialogue形式的输入时，部署N台datanode就需要输入N遍！同时新建用户也是需要输入用户密码的操作！！

Linux Expect就是用来自动化处理这些需求的。Except能根据提示来实现相应的输入。

```
[hadoop@master1 hadoop-deploy-0.0.1]$ ssh-copy-id localhost
The authenticity of host 'localhost (::1)' can't be established.
RSA key fingerprint is 4e:fe:7a:0a:98:6e:9a:ab:af:e4:65:51:9b:3d:e0:99.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'localhost' (RSA) to the list of known hosts.
hadoop@localhost's password: 
Now try logging into the machine, with "ssh 'localhost'", and check in:

  .ssh/authorized_keys

to make sure we haven't added extra keys that you weren't expecting.
```

根据需要**提示信息**，以及需要**输入的信息**，可以编写对应expect脚本来进行自动化。

```
	[hadoop@master1 hadoop-deploy-0.0.1]$ cat bin/ssh-copy-id.expect 
	#!/usr/bin/expect  

	## Usage $0 [user@]host password

	set host [lrange $argv 0 0];
	set password [lrange $argv 1 1] ;

	set timeout 30;

	spawn ssh-copy-id $host ;

	expect {
	  "(yes/no)?" { send yes\n; exp_continue; }
	  "password:" { send $password\n; exp_continue; }
	}

	exec sleep 1;
```

同样新建用户初始化密码的操作一样可以使用expect来使用：

```
	[hadoop@master1 hadoop-deploy-0.0.1]$ cat bin/passwd.expect
	#!/usr/bin/expect  

	## Usage $0 host username password

	set host [lrange $argv 0 0];
	set username [lrange $argv 1 1];
	set password [lrange $argv 2 2] ;

	set timeout 30;

	##

	spawn ssh $host useradd $username ;

	exec sleep 1;

	##

	spawn ssh $host passwd $username ;

	## password and repasswd all use this
	expect {
	  "password:" { send $password\n; exp_continue; }
	}

	exec sleep 1;
```

有了上面的脚本，预定义每台机器的root密码，使用ssh-copy-id.expect建立到各台datanode机器的无密钥登录；然后passwd.expect脚本分发给各台机器，然后使用ssh进行运行脚本建立用户初始化密码。

Expect仅在master机器上安装就可以。安装程序的如下：

```
yum install expect
```

or

```
rpm -ivh tcl-8.5.7-6.el6.x86_64.rpm
rpm -ivh expect-5.44.1.15-5.el6_4.x86_64.rpm
```

