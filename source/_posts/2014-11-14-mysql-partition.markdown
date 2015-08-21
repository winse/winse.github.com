---
layout: post
title: "mysql分区"
date: 2014-11-14 15:05:50 +0800
comments: true
categories: [tools]
---

Windows8 Mysql安装后数据默认放在`C:\ProgramData\MySQL\MySQL Server 5.6\data`下。

> 2、MyISAM数据库表文件：
> .MYD文件：即MY Data，表数据文件
> .MYI文件：即MY Index，索引文件
> .log文件：日志文件
> 
> 3、InnoDB采用表空间（tablespace）来管理数据，存储表数据和索引，
> InnoDB数据库文件（即InnoDB文件集，ib-file set）：
>   ibdata1、ibdata2等：系统表空间文件，存储InnoDB系统信息和用户数据库表数据和索引，所有表共用
>   .ibd文件：单表表空间文件，每个表使用一个表空间文件（file per table），存放用户数据库表数据和索引
>   日志文件： ib_logfile1、ib_logfile2

```
create database hello;
use hello;
create table abc ( name varchar(1000), age int );
insert into abc values ("1", 1);

create table abc_myisam ( name varchar(100), age int ) engine=myisam;
insert into abc_myisam values ( '1', 1), ('2',2);
alter table abc_myisam partition by hash(age) partitions 4 ;

insert into abc_myisam values ( '11', 10), ('2',20), ( '1', 11), ('2',21), ( '1', 21), ('2',22), ( '1', 31), ('2',32), ( '1', 41), ('2',24), ( '1', 15), ('2',23) ;
```

最终库目录如下:

![](http://file.bmob.cn/M00/D2/16/oYYBAFRlrMaAAAdoAADDsNJhdNs617.png)

根据月份来进行分区：

```
--最好按照月份分区(date需要为日期类型)
alter table abc_myisam PARTITION BY RANGE (extract(YEAR_MONTH from date)) (  
    PARTITION p410 VALUES LESS THAN (201411),  
    PARTITION p411 VALUES LESS THAN (201412),  
    PARTITION p412 VALUES LESS THAN (201501),  
	PARTITION p501 VALUES LESS THAN (201502), 
	PARTITION p502 VALUES LESS THAN (201503), 
	PARTITION p503 VALUES LESS THAN (201504), 
	PARTITION p504 VALUES LESS THAN (201505), 
	PARTITION p505 VALUES LESS THAN (201506), 
    PARTITION p0 VALUES LESS THAN MAXVALUE  
)
```

根据日期来分区：

```
alter table t_dta_activeresources_ip PARTITION BY RANGE (to_days(day)) (  
    PARTITION p0 VALUES LESS THAN (735926),  
PARTITION p141124 VALUES LESS THAN (735927),
PARTITION p141125 VALUES LESS THAN (735928),
PARTITION p141126 VALUES LESS THAN (735929),
PARTITION p88 VALUES LESS THAN MAXVALUE  
)
```

查询时执行计划带上partitions可以查看命中的是那个分区：

```
mysql> explain select * from t_dta_illegalweb where day='2015-01-04';
+----+-------------+------------------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table            | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+------------------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | t_dta_illegalweb | ALL  | NULL          | NULL | NULL    | NULL | 1335432 | Using where |
+----+-------------+------------------+------+---------------+------+---------+------+---------+-------------+
1 row in set

mysql> explain partitions
 select * from t_dta_illegalweb where day='2015-01-04';
+----+-------------+------------------+------------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table            | partitions | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+------------------+------------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | t_dta_illegalweb | p150104    | ALL  | NULL          | NULL | NULL    | NULL | 1335432 | Using where |
+----+-------------+------------------+------------+------+---------------+------+---------+------+---------+-------------+
1 row in set
```

如果清理掉分区的数据后，再查看执行计划：

```
mysql> alter table t_dta_illegalweb truncate partition p150104;
Query OK, 0 rows affected

mysql> explain partitions select * from t_dta_illegalweb where day='2015-01-04';
+----+-------------+-------+------------+------+---------------+------+---------+------+------+-----------------------------------------------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | Extra                                               |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+-----------------------------------------------------+
|  1 | SIMPLE      | NULL  | NULL       | NULL | NULL          | NULL | NULL    | NULL | NULL | Impossible WHERE noticed after reading const tables |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+-----------------------------------------------------+
1 row in set
```

## 打开日志开关

默认mysql是没有打开记录一般日志的开关的，可以通过命令行修改参数。对于查看具体执行了那些sql语句，调试很有帮助。

```
mysql> set global general_log = 1;
Query OK, 0 rows affected

mysql> SHOW  GLOBAL VARIABLES LIKE '%log%';
```

## 参考

* [MySQL数据文件介绍及存放位置](http://blog.csdn.net/yaotinging/article/details/6671506)
* [MySQL的表分区](http://lehsyh.iteye.com/blog/732719)
* <http://lobert.iteye.com/blog/1955841>
* <http://blog.csdn.net/jiao_fuyou/article/details/14214213>
* <http://database.51cto.com/art/201002/184392.htm>
* [mysql不重启清理日志](http://dev.mysql.com/doc/refman/5.5/en/error-log.html)
* <http://pangge.blog.51cto.com/6013757/1319304>
* <http://bbs.csdn.net/topics/70096519>
* <http://bbs.csdn.net/topics/350138520>
* <http://www.iteye.com/topic/408701>
* <http://www.blogjava.net/allrounder/articles/323591.html>