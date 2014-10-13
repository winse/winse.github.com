---
layout: post
title: "计算出从1到100之间所有奇数的平方之和"
date: 2014-09-04 14:15:40 +0800
comments: true
categories: [scala]
---

[计算出从1到100之间所有奇数的平方之和，代码50字符内（QQ群的验证框长度限制为50）](http://freewind.github.io/posts/scala-group-entry-problem/)。

如题，题目没啥难度，这50字符的条件莫名的增添压迫感。其实java写也不用50个字符就能搞定的 ！

```
// (1 to 50) foreach {x => print("0")}
00000000000000000000000000000000000000000000000000

// java
int sum=0;for(int i=0;i<100;i+=2)sum+=i*i;

// scala
(1 to 100).map(a=>if(a%2==1)a*a else 0).foldLeft(0)(_+_)
(0 to 100).foldLeft(0)(_+((a:Int)=>if(a%2==1)a*a else 0)(_))
var sum=0;for(i<- 1 to 100)if(i%2==1)sum+=i*i
var sum=0;for(i<- 1 to 100; if i%2==1)sum+=i*i

(1 to 100 by 2).foldLeft(0)(_+((a:Int)=>a*a)(_))
(1 to 100 by 2).map(a=>a*a).foldLeft(0)(_+_)
var sum=0;for(i<- 1 to 100 by 2)sum+=i*i
(1 to 100 by 2).map(a=>a*a).reduce(_+_)
```

`(1 to 100 by 2).map(a=>a*a).reduce(_+_)`是里面最短的应该也是最好的了，既没有定义变量同时意义清晰一看就懂。
