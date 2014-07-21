---
layout: post
title: "Filter mapping url-pattern that excludes subdirectories"
date: 2012-07-26 14:04
comments: true
categories: [java]
---

需求其实就是把eclipse osgi导出的应用嵌入到原有的ssh开发的程序中。
但是整合过程遇到一些问题。ssh会对资源进行拦截处理，导致OSGi获取不到请求，OSGi和ssh的应用最好分开管理。
可以利用SSH提供的excludePattern配置正则表达式来实现排除处理！

## Struts拦截器配置

```
	<filter> 
	  <filter-name>struts-cleanup</filter-name> 
	  <filter-class> 
	   org.apache.struts2.dispatcher.ActionContextCleanUp 
	  </filter-class> 
	</filter>
	<filter-mapping> 
	  <filter-name>struts-cleanup</filter-name> 
	  <url-pattern>/*</url-pattern> 
	</filter-mapping> 

	<filter>
	  <filter-name>struts</filter-name>
	  <filter-class>org.apache.struts2.dispatcher.FilterDispatcher</filter-class>		
	</filter>
	<filter-mapping>
	  <filter-name>struts</filter-name>
	  <url-pattern>*.action</url-pattern>
	</filter-mapping>
	<filter-mapping>
	  <filter-name>struts</filter-name>
	  <url-pattern>*.do</url-pattern>
	</filter-mapping>
	<filter-mapping>
	  <filter-name>struts</filter-name>
	  <url-pattern>*.htm</url-pattern>
	</filter-mapping>
	<filter-mapping>
	  <filter-name>struts</filter-name>
	  <url-pattern>/struts/*</url-pattern>
	</filter-mapping>
```

## 添加OSGi支持

把eclipse osgi应用嵌入需要在web.xml中添加：

```
	<servlet id="bridge">
		<servlet-name>equinoxbridgeservlet</servlet-name>
		<servlet-class>org.eclipse.equinox.servletbridge.BridgeServlet</servlet-class>
		<init-param>
			<param-name>commandline</param-name>
			<param-value>-console</param-value>			
		</init-param>		
		<init-param>
			<param-name>enableFrameworkControls</param-name>
			<param-value>true</param-value>			
		</init-param>
		<init-param>
			<param-name>extendedFrameworkExports</param-name>
			<param-value></param-value>			
		</init-param>	
		<load-on-startup>1</load-on-startup>
	</servlet>
	<servlet-mapping>
		<servlet-name>equinoxbridgeservlet</servlet-name>
		<url-pattern>
			/osgi/*
		</url-pattern>
	</servlet-mapping>
```

## 整合遇到的问题及解决

由于struts的filter过滤了htm，导致osgi的htm文件被struts"劫"取了~~

经过一番挣扎，解决方法如下：

在struts过滤器中增加排除参数。

```
  <filter>
  	<filter-name>struts</filter-name>
  	<filter-class>
  		org.apache.struts2.dispatcher.ng.filter.StrutsPrepareAndExecuteFilter
  	</filter-class>
  	<init-param>
  		<param-name>struts.action.excludePattern</param-name>
  		<param-value>/osgi/.*</param-value>
  	</init-param>
  </filter>
```

## 为啥怎么弄，解释如下：

**1 读取init-param初始化参数excludedPatterns**

```
    protected List<Pattern> excludedPatterns = null;

    public void init(FilterConfig filterConfig) throws ServletException {
        InitOperations init = new InitOperations();
        try {
            FilterHostConfig config = new FilterHostConfig(filterConfig);
            init.initLogging(config);
            Dispatcher dispatcher = init.initDispatcher(config);
            init.initStaticContentLoader(config, dispatcher);

            prepare = new PrepareOperations(filterConfig.getServletContext(), dispatcher);
            execute = new ExecuteOperations(filterConfig.getServletContext(), dispatcher);
            this.excludedPatterns = init.buildExcludedPatternsList(dispatcher); // 获取不被Struts处理的请求Regex模式

            postInit(dispatcher, filterConfig);
        } finally {
            init.cleanup();
        }

    }
```

** 2 使用excludedPatterns**

```
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) 
                        throws IOException, ServletException {
        //父类向子类转：强转为httpReq请求、httpResp响应
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

		try {
			//。。。@@根据Regex模式(excludedPatterns)对请求进行处理
			if ( excludedPatterns != null && prepare.isUrlExcluded(request, excludedPatterns)) {
				chain.doFilter(request, response);
			} else {
				request = prepare.wrapRequest(request);
				ActionMapping mapping = prepare.findActionMapping(request, response, true);
				if (mapping == null) {
					boolean handled = execute.executeStaticResourceRequest(request, response);
					if (!handled) {
						chain.doFilter(request, response);
					}
				} else {
					execute.executeAction(request, response, mapping);
				}
			}
		} finally {
			 prepare.cleanupRequest(request);
		}
    }
```

## 后记

其实SSH就是对请求进行过滤拦截转发！Struts提供了不处理请求配置罢了。

看到的其他实现：

```
	// First cast ServletRequest to HttpServletRequest.
	HttpServletRequest hsr = (HttpServletRequest) request;
	
	// Check if requested resource is not in /test folder.
	if (!hsr.getServletPath().startsWith("/test/")) {
		// Not in /test folder. Do your thing here.
	}
```


web.xml中<url-pattern>的3种写法

1. 完全匹配 <url-pattern>/test/list.do</url-pattern>
2. 目录匹配 <url-pattern>/test/*</url-pattern>
3. 扩展名匹配 <url-pattern>*.do</url-pattern>

servlet-mapping的重要规则：

* 容器会首先查找完全匹配，如果找不到，再查找目录匹配，如果也找不到，就查找扩展名匹配。
* 如果一个请求匹配多个“目录匹配”，容器会选择最长的匹配。

## 参考资源：

* <http://ari.iteye.com/blog/829843>
* <http://www.docjar.org/html/api/org/apache/struts2/dispatcher/ng/filter/StrutsPrepareAndExecuteFilter.java.html>
* [servlet-mapping](http://selectshy.iteye.com/blog/1293458)
* [Struts2的工作原理](http://space.itpub.net/13750068/viewspace-493899)
* [Can I exclude some concrete urls from <url-pattern> inside <filter-mapping>?](http://stackoverflow.com/questions/3125296/can-i-exclude-some-concrete-urls-from-url-pattern-inside-filter-mapping)
* [Filter mapping url-pattern that excludes subdirectories](http://stackoverflow.com/questions/3466897/filter-mapping-url-pattern-that-excludes-subdirectories)
* <http://www.blogjava.net/liuspring/archive/2008/09/01/226073.html>
* [urlrewrite](http://tuckey.org/urlrewrite/)
* <http://urlrewritefilter.googlecode.com/svn/trunk/src/doc/manual/4.0/index.html#filterparams>

* * * 
[【原文地址】](http://winse.iteye.com/blog/1607884)
