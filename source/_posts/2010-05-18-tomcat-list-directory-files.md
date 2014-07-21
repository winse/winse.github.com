---
layout: post
title: "Tomcat列出服务器目录下的文件"
date: 2010-05-18 09:33
comments: true
categories: [tools]
---

在Tomcat中,我们在IE地址栏中输入的URL是一个目录时，列出该目录下的文件链接!

在conf/web.xml中修改listings参数的值为true , 默认是false为不显示。

```
<servlet>
	<servlet-name>default</servlet-name>
	<servlet-class>
		org.apache.catalina.servlets.DefaultServlet
	</servlet-class>
	<init-param>
		<param-name>debug</param-name>
		<param-value>0</param-value>
	</init-param>
	<init-param>
		<param-name>listings</param-name>
		<param-value>true</param-value>
	</init-param>
	<load-on-startup>1</load-on-startup>
</servlet>
```

重新启动Tomcat，即可！

## 参考

* [列出该目录下的文件链接!](http://www.blogjava.net/cool2009/archive/2009/05/03/268676.html)

* * * 
[【原文地址】](http://winsefirst.blog.sohu.com/151787483.html)
