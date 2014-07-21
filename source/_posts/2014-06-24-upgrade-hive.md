---
layout: post
title: "upgrade hive: 0.12.0 to 0.13.1"
date: 2014-6-20 18:34:59
categories: [hive]
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

# 测试hive-jdbc
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
