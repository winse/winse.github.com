---
layout: post
title: "nginx服务配置"
date: 2014-11-13 10:16:17 +0800
comments: true
categories: [tools]
---

配置nginx作为网页快照的服务，需要理解好配置`root`的涵义！

## 安装、启动

首先安装，然后修改配置：

```
yum install nginx 

less /etc/nginx/nginx.conf
less /etc/nginx/conf.d/default.conf 

service nginx restart
```

实际操作中没有root，只能自己编译了：

```
下载nginx，pcre-8.36.zip，zlib-1.2.3.tar.gz解压到src下。
cd nginx-1.7.7
./configure --prefix=/home/omc/tools/nginx --with-pcre=src/pcre --with-zlib=src/zlib
make && make install

cd /home/omc/tools/nginx
vi conf/nginx.conf # 修改listen的端口，80要root才能起
sbin/nginx
sbin/nginx -s reload
```

如果编译的目录和真正存放程序的路径不一致时，可以使用`-p`参数来指定。

```
cd nginx
sbin/nginx -p $PWD
sbin/nginx -s reload -p $PWD
```

## 静态页面服务配置

下面具体说说配置的涵义：

* root（不管在那个配置节点下）位置都对应 请求的根路径。

```
    location /static {
        root  /usr/share/static/html;
        autoindex on;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
```

* location的`/static`对应的是访问目录`/usr/share/static/html/static`下的内容，请求`/static/hello.html`对应到`/usr/share/static/html/static/hello.html`。也就是说节点下的root目录 对应 的是 访问地址的`/`。
* autoindex可以用于list列出目录内容。

![](http://file.bmob.cn/M00/05/49/ooYBAFRkHkmAe3wcAACCDsZ0Oc8983.png)

配置了两个路径后，问题来了：如果`/usr/share/nginx/html/`也有目录static，那nginx会访问谁？**nginx来先匹配配置，访问/static定位到`/usr/share/static/html`**。

```
    location /static {
        root  /usr/share/static/html;
		try_files $uri /static/404.html;
    }
```

* try_files可以设置默认页面，如`/usr/share/static/html/static`目录下不存在abc.html，那么会内部重定向到`/static/404.html`。这里路径要`/static`下面。

try_files还可以返回状态值，跳转到对应状态的页面：

```
location / {
    try_files $uri $uri/ $uri.html =404;
}
```

![](http://file.bmob.cn/M00/D1/D0/oYYBAFRkJ6eAc8UiAAEKid3ICHw052.png)

如果try_files的所给出的地址不包括`$uri`时，请求会被重定向配置指向的新代理服务：

```
location / {
    try_files $uri $uri/ @backend;
}

location @backend {
    proxy_pass http://backend.example.com;
}
```

## 实践

在实际操作遇到的不能访问的问题，配置本机的其他JavaWeb应用，但是在登录后，点其他链接总是跳转到登陆页。可以查看下真正请求的地址。

```
	location /omc {
			proxy_pass http://REAL-IP:9000/omc;
			#proxy_pass http://localhost:9000/omc;
	}
```

填写localhost不能访问，但是填具体的外网IP时是可以访问的。查看后，在页面定义了`<base href="${basedir}/>`导致请求都跳转到localhost了。在客户端肯定就访问失败了。这个需要特别注意下。

![](http://file.bmob.cn/M00/05/C3/ooYBAFRpn1qAKNKiAACUae7DmjY717.png)

在特定的情况下，文件不一定是html后缀的（如：txt），如果要在浏览器解析html，需要配置content-type标题头。同时访问的url和真实存放的文件的路径有出处时，可以通过rewrite指令来进行适配。

```
    server {
		...
        location /snapshot {
            root   /home/ud/html-snapshot;
            add_header content-type "text/html";
            rewrite ^/snapshot/.*/(.*)$  /snapshot/$1   last;
            try_files $uri $uri.html $uri.htm =404;
        }
```

## 主备配置

```
upstream backend {
    server backend1.example.com 
    server backup1.example.com  backup;
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```

* [nginx upstream](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#upstream)

## 防火墙跳转情况下nginx配置

如在防火墙做了11111端口映射到9000端口，如果按照的配置，应用的redirect会被nginx转换为9000端口发给用户，而不是原始的用户访问的11111端口。导致不一致甚至不能访问。

```
  location ~ \.do$ {
    proxy_pass              http://localhost:8080;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        Host $http_host;
  }                                                                                                       
  location ~ \.jsp$ {
    proxy_pass              http://localhost:8080;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        Host $http_host;
  }
```

* [JavaServers](http://wiki.nginx.org/JavaServers)
* [Apache ProxyPassReverse](http://wiki.nginx.org/LikeApache)
* [NginxHttpProxyModule](http://wiki.nginx.org/NginxHttpProxyModule#proxy_pass)

## rewrite

flag有两个last和break参数。last和break最大的不同在于

- break是终止当前location的rewrite检测,而且不再进行location匹配 
– last是终止当前location的rewrite检测,但会继续重试location匹配并处理区块中的rewrite规则

结果rewrite的结果重新命中了location /download/ 虽然这次并没有命中rewrite规则的正则表达式,但因为缺少终止rewrite的标志,其仍会不停重试download中rewrite规则直到达到10次上限返回HTTP 500。

配置：

```
        location / {
           root   html;

rewrite ^/snapshot/[^\/]*/(.*)$  /snapshot/$1 last;
           index  index.html index.htm;
        }
```

日志：

```
2015/03/13 11:53:42 [error] 32395#0: *17 rewrite or internal redirection cycle while processing "/snapshot/45/c7/2f/45c72f9a926d2b72b0c705a125d2764a.txt", client: 132.122.237.189, server: localhost, request: "GET //snapshot/1/2/3/4/5/6/7/8/9/10/11/45/c7/2f/45c72f9a926d2b72b0c705a125d2764a.txt HTTP/1.1", host: "umcc97-44:8888"

2015/03/13 11:54:14 [error] 32395#0: *20 open() "/home/hadoop/nginx/html/snapshot/45c72f9a926d2b72b0c705a125d2764a.txt" failed (2: No such file or directory), client: 132.122.237.189, server: localhost, request: "GET //snapshot/1/2/3/4/5/45c72f9a926d2b72b0c705a125d2764a.txt HTTP/1.1", host: "umcc97-44:8888"
```

10次以上就报错，少于10次是ok的。

* [Nginx Rewrite详解](http://www.cnblogs.com/dami520/archive/2012/08/16/2642967.html)

## 参考

* [Serving Static Content](http://nginx.com/resources/admin-guide/serving-static-content/)
* [NGINX Web Server](http://nginx.com/resources/admin-guide/web-server/)
* [nginx rewrite规则](http://www.cnblogs.com/cgli/archive/2011/05/16/2047920.html)