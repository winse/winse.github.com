---
layout: post
title: "upgrade hive: 0.12.0 to 0.13.1"
date: 2014-6-20 18:34:59
categories: [hive]
comments: true
---

由于hive-0.12.0的FileSystem使用不当导致内存溢出问题，最终考虑升级hive。升级的过程没想象中的那么可怕，步骤很简单：对源数据库执行升级脚本，拷贝原hive-0.12.0的配置和jar，然后把添加jar重启hiverserver2即可。

## 修改环境变量

```
HIVE_HOME=/home/hadoop/apache-hive-0.13.1-bin
PATH=$JAVA_HOME/bin:$HIVE_HOME/bin:$PATH
```

## 升级metadata

```
[hadoop@ismp0 ~]$ cd apache-hive-0.13.1-bin/scripts/metastore/upgrade/mysql/

[hadoop@ismp0 mysql]$ mysql -uXXX -hXXX -pXXX
mysql> use hive
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> source upgrade-0.12.0-to-0.13.0.mysql.sql
+--------------------------------------------------+
|                                                  |
+--------------------------------------------------+
| Upgrading MetaStore schema from 0.12.0 to 0.13.0 |
+--------------------------------------------------+
1 row in set, 1 warning (0.00 sec)

+-----------------------------------------------------------------------+
|                                                                       |
+-----------------------------------------------------------------------+
| < HIVE-5700 enforce single date format for partition column storage > |
+-----------------------------------------------------------------------+
1 row in set, 1 warning (0.00 sec)

Query OK, 0 rows affected (0.22 sec)
Rows matched: 0  Changed: 0  Warnings: 0

+--------------------------------------------+
|                                            |
+--------------------------------------------+
| < HIVE-6386: Add owner filed to database > |
+--------------------------------------------+
1 row in set, 1 warning (0.00 sec)

Query OK, 1 row affected (0.33 sec)
Records: 1  Duplicates: 0  Warnings: 0

Query OK, 1 row affected (0.16 sec)
Records: 1  Duplicates: 0  Warnings: 0

+---------------------------------------------------------------------------------------------+
|                                                                                             |
+---------------------------------------------------------------------------------------------+
| <HIVE-6458 Add schema upgrade scripts for metastore changes related to permanent functions> |
+---------------------------------------------------------------------------------------------+
1 row in set, 1 warning (0.00 sec)

Query OK, 0 rows affected (0.06 sec)

Query OK, 0 rows affected (0.06 sec)

+----------------------------------------------------------------------------------+
|                                                                                  |
+----------------------------------------------------------------------------------+
| <HIVE-6757 Remove deprecated parquet classes from outside of org.apache package> |
+----------------------------------------------------------------------------------+
1 row in set, 1 warning (0.00 sec)

Query OK, 0 rows affected (0.04 sec)
Rows matched: 0  Changed: 0  Warnings: 0

Query OK, 0 rows affected (0.01 sec)
Rows matched: 0  Changed: 0  Warnings: 0

Query OK, 0 rows affected (0.01 sec)
Rows matched: 0  Changed: 0  Warnings: 0

Query OK, 0 rows affected (0.07 sec)

Query OK, 0 rows affected (0.12 sec)

Query OK, 0 rows affected (0.07 sec)

Query OK, 0 rows affected (0.06 sec)

Query OK, 1 row affected (0.05 sec)

Query OK, 0 rows affected (0.06 sec)

Query OK, 0 rows affected (0.15 sec)
Records: 0  Duplicates: 0  Warnings: 0

Query OK, 0 rows affected (0.06 sec)

Query OK, 1 row affected (0.05 sec)

Query OK, 0 rows affected (0.07 sec)

Query OK, 0 rows affected (0.06 sec)

Query OK, 1 row affected (0.05 sec)

Query OK, 1 row affected (0.07 sec)
Rows matched: 1  Changed: 1  Warnings: 0

+-----------------------------------------------------------+
|                                                           |
+-----------------------------------------------------------+
| Finished upgrading MetaStore schema from 0.12.0 to 0.13.0 |
+-----------------------------------------------------------+
1 row in set, 1 warning (0.00 sec)

mysql> 
mysql> 
mysql> exit
Bye

[hadoop@ismp0 ~]$ vi .bash_profile
[hadoop@ismp0 ~]$ source .bash_profile
[hadoop@ismp0 ~]$ cd apache-hive-0.13.1-bin
[hadoop@ismp0 apache-hive-0.13.1-bin]$ cd conf/
[hadoop@ismp0 conf]$ cp ~/hive-0.12.0/conf/hive-site.xml ./
[hadoop@ismp0 conf]$ cd ..
[hadoop@ismp0 apache-hive-0.13.1-bin]$ cp ~/hive-0.12.0/lib/mysql-connector-java-5.1.21-bin.jar lib/
[hadoop@ismp0 apache-hive-0.13.1-bin]$ hive
[hadoop@ismp0 apache-hive-0.13.1-bin]$ hive

hive>  select count(*) from t_ods_idc_isp_log2 where day=20140624;
Total jobs = 1
Launching Job 1 out of 1
Number of reduce tasks determined at compile time: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapreduce.job.reduces=<number>
Starting Job = job_1403006477300_3403, Tracking URL = http://umcc97-79:8088/proxy/application_1403006477300_3403/
Kill Command = /home/hadoop/hadoop-2.2.0/bin/hadoop job  -kill job_1403006477300_3403
Hadoop job information for Stage-1: number of mappers: 2; number of reducers: 1
2014-06-24 17:19:07,618 Stage-1 map = 0%,  reduce = 0%
2014-06-24 17:19:15,283 Stage-1 map = 50%,  reduce = 0%, Cumulative CPU 2.37 sec
2014-06-24 17:19:16,360 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 5.49 sec
2014-06-24 17:19:22,749 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 7.99 sec
MapReduce Total cumulative CPU time: 7 seconds 990 msec
Ended Job = job_1403006477300_3403
MapReduce Jobs Launched: 
Job 0: Map: 2  Reduce: 1   Cumulative CPU: 7.99 sec   HDFS Read: 19785618 HDFS Write: 6 SUCCESS
Total MapReduce CPU Time Spent: 7 seconds 990 msec
OK
77625
Time taken: 36.387 seconds, Fetched: 1 row(s)
hive> 

[hadoop@ismp0 apache-hive-0.13.1-bin]$ nohup bin/hiveserver2 &

$# 测试hive-jdbc
[hadoop@ismp0 apache-hive-0.13.1-bin]$ bin/beeline 
Beeline version 0.13.1 by Apache Hive
beeline> !connect jdbc:hive2://10.18.97.22:10000/
scan complete in 7ms
Connecting to jdbc:hive2://10.18.97.22:10000/
Enter username for jdbc:hive2://10.18.97.22:10000/: hadoop
Enter password for jdbc:hive2://10.18.97.22:10000/: 
Connected to: Apache Hive (version 0.13.1)
Driver: Hive JDBC (version 0.13.1)
Transaction isolation: TRANSACTION_REPEATABLE_READ
0: jdbc:hive2://10.18.97.22:10000/> show tables;
+-------------------------+
|        tab_name         |
+-------------------------+
...
| test_123                |
+-------------------------+
10 rows selected (2.547 seconds)
0: jdbc:hive2://10.18.97.22:10000/>  select count(*) from t_ods_idc_isp_log2 where day=20140624;
+--------+
|  _c0   |
+--------+
| 77625  |
+--------+
1 row selected (37.463 seconds)
0: jdbc:hive2://10.18.97.22:10000/> 


```

上一篇tez的安装使用中由于hive的缘故进行了回退，现在升级到hive-0.13后，也在hive上试下tez的功能：

* 本地添加tez依赖，设置环境变量
* MR添加tez依赖，添加tez-site.xml
* 切换到tez的engine

```
$# 已上传到HDFS
$ hadoop fs -mkdir /apps
$ hadoop fs -put tez-0.4.0-incubating /apps/
$ hadoop fs -ls /apps
Found 1 items
drwxr-xr-x   - hadoop supergroup          0 2014-09-09 16:19 /apps/tez-0.4.0-incubating

$ cat etc/hadoop/tez-site.xml 
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>tez.lib.uris</name>
    <value>${fs.default.name}/apps/tez-0.4.0-incubating,${fs.default.name}/apps/tez-0.4.0-incubating/lib/</value>
  </property>
</configuration>

$ export HADOOP_CLASSPATH=${TEZ_HOME}/*:${TEZ_HOME}/lib/*:$HADOOP_CLASSPATH
$ apache-hive-0.13.1-bin/bin/hive
hive> set hive.execution.engine=tez;
hive> select count(*) from t_ods_idc_isp_log2 ;
Time taken: 24.926 seconds, Fetched: 1 row(s)

hive> set hive.execution.engine=mr;                              
hive> select count(*) from t_ods_idc_isp_log2 where day=20140720;
Time taken: 40.585 seconds, Fetched: 1 row(s)

$# @hive-env.sh
 # export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$TEZ_HOME/*:$TEZ_HOME/lib/*
$ last_hour=2014090915
$ hive --hiveconf hive.execution.engine=tez -e "select houseId, count(*) 
from 
(
select houseId
from t_house_monitor2
where hour=$last_hour
group by from_unixtime(cast(accesstime as bigint), 'yyyyMMdd'),houseId,IP,port,domain,serviceType,illegalType,currentState,usr,icpError,regerror,regDomain,use_type,real_useType
) hs
group by houseId"
```

简单从时间上看，还是有效果的。

![](http://file.bmob.cn/M00/04/A2/wKhkA1PSPSeAb1wWAAER_4gjIug339.png)

## 调试Hive

也很简单，hive脚本已经默认集成了这个功能，设置下DEBUG环境变量即可。

```
[hadoop@master1 ~]$ less apache-hive-0.13.1-bin/bin/ext/debug.sh
[hadoop@master1 bin]$ less hive

$# 脚本最终会把调试的参数` -agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend=y`加入到HADOOP_CLIENT_OPTS中，最后合并到HADOOP_OPTS传递给java程序。

[hadoop@master1 bin]$ DEBUG=true hive
Listening for transport dt_socket at address: 8000
```

然后通过eclipse的远程调试即可一步步的查看整个过程。下面断点处为记录解析功能：

![](http://file.bmob.cn/M00/0A/D4/wKhkA1QEASyAM9VEAAHQS7gZJlo672.png)

## 编译源码导入eclipse

```
$ git clone https://github.com/apache/hive.git

winse@Lenovo-PC /cygdrive/e/git/hive
$ git checkout branch-0.13

E:\git\hive>mvn clean package eclipse:eclipse -DskipTests -Dmaven.test.skip=true -Phadoop-2
```

