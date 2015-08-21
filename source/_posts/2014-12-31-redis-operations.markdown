---
layout: post
title: "redis维护"
date: 2014-12-31 23:14:57 +0800
comments: true
categories: [redis]
---

在使用过程中，接触最多的就是它的commands。除了string/hashmap/set/sortedlist的基本使用方式外，下面总结平时会经常使用的命令：

## 启动，客户端连接

```
[root@docker redis-2.8.13]# nohup src/redis-server --port 6370 &

[root@docker redis-2.8.13]# src/redis-cli -p 6370
127.0.0.1:6370> 
```

## 获取redis的整体状态

```
127.0.0.1:6370> info
...
# Memory
used_memory:1415161160
used_memory_human:1.32G
used_memory_rss:0
used_memory_peak:1415161160
used_memory_peak_human:1.32G
used_memory_lua:33792
mem_fragmentation_ratio:0.00
mem_allocator:jemalloc-3.6.0
...
# CPU
used_cpu_sys:52.47
used_cpu_user:10.07
used_cpu_sys_children:0.00
used_cpu_user_children:0.00

# Keyspace
db0:keys=4253125,expires=0,avg_ttl=0
```

列出的信息，包括了版本、内存/CPU使用、请求数、键值对等信息。通过这些基本了解redis运行情况。

## 清空数据库

对于数据量少的情况下，可以使用flushall来清理记录。

```
127.0.0.1:6370> set abc 1234
OK
127.0.0.1:6370> keys *
1) "abc"
127.0.0.1:6370> flushall
OK
127.0.0.1:6370> keys *
(empty list or set)
```

数据量大的情况不建议使用flushall，可以直接把rdb数据文件干掉，然后重启redis服务就可以了（找不到数据文件后，就是一个新的库）。

## 随机获取一个键

```
127.0.0.1:6370> mset a 1 b 2 c 3 d 4 e 5 f 6 
OK
127.0.0.1:6370> RANDOMKEY
"a"
127.0.0.1:6370> RANDOMKEY
"f"
127.0.0.1:6370> RANDOMKEY
"e"
127.0.0.1:6370> RANDOMKEY
"a"
```

## 遍历获取键值

一般情况下，我们会使用`keys PATTERN`来查找匹配的键值。但是，如果数据量很大，keys操作会很消耗系统资源，`stop the world`的事情不是我们想看到的！此时，可以通过scan/hscan/zscan/ssan命令依次获取。

* 获取库中的键值

```
127.0.0.1:6370> eval "for i=1,100000 do redis.call('set', 'a' .. i, i) end" 0
(nil)
(0.98s)
```

正式环境我们无法预估匹配的键的数量，一根筋的使用keys命令可能并不明智。如果数据量很多，等不到结束应该就会ctrl+c了。这种情况下，可以使用scan命令：

```
127.0.0.1:6370> scan 0 match ismi:domain:*.upaiyun.com
1) "6553600"
2) 1) "ismi:domain:KunMing:1415646303170928524.test.b0.upaiyun.com"
   2) "ismi:domain:KunMing:1415392926002699280.test.b0.upaiyun.com"
   3) "ismi:domain:KunMing:141489373375899237.test.b0.upaiyun.com"
127.0.0.1:6370> scan 0 match ismi:domain:*.upaiyun.com count 10
1) "6553600"
2) 1) "ismi:domain:KunMing:1415646303170928524.test.b0.upaiyun.com"
   2) "ismi:domain:KunMing:1415392926002699280.test.b0.upaiyun.com"
   3) "ismi:domain:KunMing:141489373375899237.test.b0.upaiyun.com"

```

Basically with COUNT the user specified the amount of work that should be done at every call in order to retrieve elements from the collection. This is just an hint for the implementation, however generally speaking this is what you could expect most of the times from the implementation.

COUNT数值的意思应该是匹配操作的次数，而不是查询结果的个数。通过和`scan 0`对比可以得出来。


同理，对于set（smembers）可以使用sscan，sortedlist可以使用zcan等。

## lua脚本

redis内置的脚本语言，直接使用脚本可以减少客户端和服务端连接（多次请求）的压力。例如要批量删除一些键值：

```
src/redis-cli keys 'v2:*' | awk '{print $1}' | while read line; do src/redis-cli del $line ; done
```

先获取匹配的key，然后使用shell再次调用redis的客户端进行删除。表面上看起来没啥问题，如果匹配的key很多，会产生很多的tcp连接，占用redis服务器的端口！最终端口不够用，请求报错。

此时，如果使用lua脚本的方式，就可以轻松处理。无需考虑端口等问题。

```
# 量少时可以使用
eval "local aks=redis.call('keys', 'v2:*'); if #aks >0 then redis.call('del', unpack(aks)) end" 0

# 优美
eval "local aks=redis.call('keys', 'v2:*'); for _,r in ipairs(aks) do redis.call('del', r) end" 0
```

当然，如果键不多，还可以使用一次性全部删除：

```
src/redis-cli -p $PORT del `~/redis-2.8.13/src/redis-cli -p $PORT 'keys' 'v2:*' | grep -v 'v2:ci:' | grep -v 'v2:ff' | grep -v "$(date +%Y-%m-%d)" | grep -v "$(date +%Y-%m-%d -d '-1 day')"`
```

