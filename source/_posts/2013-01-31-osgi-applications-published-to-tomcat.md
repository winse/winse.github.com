---
layout: post
title: "warproduct-OSGi应用发布到tomcat"
time: 2013-01-31 01:16
comments: true
categories: [java]
---

equinox中的内置的jetty服务器已经很优秀了，但应用可以需要用到已经成熟的技术，需要集成到如tomcat， weblogic等等容器中。（下面以tomcat容器为例， 其他已经包括了OSGi框架的容器可能会更麻烦一点）

下面按照自己的操作需要注意的关键步骤，记录一下如何把OSGi应用部署到tomcat容器中。

## 1 环境准备(或rap1.5)：

servletbridge相关插件[s1]

*   org.eclipse.equinox.http.servletbridge_1.0.300.v20120522-2049.jar
*   org.eclipse.equinox.servletbridge.extensionbundle_1.2.100.v20120522-2049
*   org.eclipse.equinox.servletbridge_1.2.200.v20120522-2049（需打包成**servletbridge.jar**）

warproduct相关插件[s2]（0.2.2.201212132117）

*   /org.eclipse.libra.warproducts.core
*   /org.eclipse.libra.warproducts.ui

## 2 打包部署到tomcat

1） 集成到tomcat容器中，得去掉就javax.servlet Plugin的依赖。需要修改：插件中对于javax.servlet插件的引用，修改为package的方式添加依赖。

![](http://dl.iteye.com/upload/attachment/0080/2124/d3429ea5-0df2-379e-bf70-361a8483e8dc.png)

2） 在已经可以运行的product的基础上 [s3]，新建warproduct导出为war [r1]。（后面的就不用讲了，和部署其他war是一样的）

*   下载[**demo.zip**](http://dl.iteye.com/topics/download/6efce6f5-d821-3619-a4a7-ae2bbdfaf783)，然后导入eclipse
*   打开/sample.server/server-web.product文件，运行"Launch an Eclipse application"
*   新建warproduct，选择"Use a launch configuration"-"server-web.product"(warproduct插件的安装参考[r1]的链接)
*   需要添加servletbridge.jar的library
*   导出成war，然后放置到tomcat/webapp目录下即可。（web.xml & launch.ini会同时导出）

![](http://dl.iteye.com/upload/attachment/0080/2140/21ca7db3-bf90-36bc-876f-d7958f677259.png)

## 3 到底发生了什么

1、这其中最牛叉的就是servletbridge.jar，其中就三个Java类：

* org/eclipse/equinox/servletbridge/BridgeServlet.java

	接收和转发请求（给真正的Servlet）；插件org.eclipse.equinox.http.servletbridge配合把真正的Servlet（org.eclipse.equinox.http.servlet.HttpServiceServlet）注册到容器（如tomcat）；同时管理Framework。

* org/eclipse/equinox/servletbridge/CloseableURLClassLoader.java

	（。。。HARD。。。）

* org/eclipse/equinox/servletbridge/FrameworkLauncher.java

	对插件的部署，启动，extensionbundle的创建/更新

2、当然，能让我们的导出工作如此轻松，**warproduct**居功至伟啊！warproduct是一个精简版的PDE-product的实现，在PDE-product的基础上实现自定义校验和添加了library的功能，以及实现自己的导出功能。~~（使用Ant导出的文章[http://www.ibm.com/developerworks/cn/web/wa-rcprap/index.html](http://www.ibm.com/developerworks/cn/web/wa-rcprap/index.html)  现在的版本都是使用warproduct，找了老久才找到一个老版本的[rold1]）~~。封装了如下的功能：

*   去掉对jetty的依赖
*   同时添加servletbridge相关插件和jar的校验
*   过滤javax.servlet插件依赖错误的提示。

```
  public static final String SERVLET_BRIDGE_ID 
    = "org.eclipse.equinox.servletbridge"; //$NON-NLS-1$

  public static final String[] BANNED_BUNDLES = new String[] { 
    "javax.servlet", //$NON-NLS-1$
    "org.eclipse.update.configurator",  //$NON-NLS-1$
    "org.eclipse.equinox.http.jetty",  //$NON-NLS-1$
    "org.mortbay.jetty.server",  //$NON-NLS-1$
    "org.mortbay.jetty.util"  //$NON-NLS-1$
  };

  public static final String[] REQUIRED_BUNDLES = new String[] { 
    "org.eclipse.equinox.servletbridge.extensionbundle", //$NON-NLS-1$
    "org.eclipse.equinox.http.registry", //$NON-NLS-1$
    "org.eclipse.equinox.registry", //$NON-NLS-1$
    "org.eclipse.equinox.http.servlet", //$NON-NLS-1$
    "org.eclipse.equinox.http.servletbridge" //$NON-NLS-1$
  };
```

+ **org.eclipse.equinox.http.servletbridge** [s1] 
+ tomcat 的功能相当于org.eclipse.equinox.http.jetty

## 源码Source

* s1： [equinox source](http://git.eclipse.org/c/equinox/rt.equinox.bundles.git/)
* s2： [warproducts demo](https://github.com/hstaudacher/org.eclipse.rap.build.examples/tree/master/warproducts)
* s3： [example](http://winse.iteye.com/blog/1601916)

## 参考：

* r1： [RAP/Equinox WAR products](http://wiki.eclipse.org/RAP/Equinox_WAR_products)
* <http://download.eclipsesource.com/~hstaudacher/warproducts/3.7>
* <http://eclipse.org/rap/developers-guide/devguide.php?topic=advanced/deployment.html&version=1.5>
* <http://eclipsesource.com/blogs/2011/02/02/equinoxrap-war-products-has-moved-hello-eclipse-libra/>
* <http://eclipsesource.com/blogs/2011/02/07/how-to-build-a-server-side-equinoxrap-application/>
* <http://eclipsesource.com/blogs/2009/08/15/building-your-equinox-based-appserver-part-1/>
* rold1： [webappbuilder](http://eclipsesource.com/blogs/2007/12/07/rap-deployment-part-2-deploying-your-application-as-a-war-file/) in [download the finished example ](http://content.screencast.com/users/eclipsenuggets/folders/eclipse/media/9c9f07f6-4b0a-4efa-844c-83e3d7e6ea4b/calc.ui.rap-war.zip?downloadOnly=true)
* <http://help.eclipse.org/galileo/index.jsp?topic=/org.eclipse.rap.help/help/html/advanced/deployment.html>
* r2： [Equinox in a Servlet Container](http://www.eclipse.org/equinox/server/)
* <http://www.eclipse.org/equinox/server/http_in_container.php>

  

* * * 
[【原文地址】](http://winseclone.iteye.com/blog/1780083)
