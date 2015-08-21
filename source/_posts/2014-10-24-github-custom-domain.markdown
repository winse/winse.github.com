---
layout: post
title: "为github pages页面设置自定义域名"
date: 2014-10-24 00:17:19 +0800
comments: true
categories: [jekyll]
---

1. 注册个域名（net.cn）
2. 添加CNAME文件（github.com）
3. 添加解析记录（net.cn）

![](http://file.bmob.cn/M00/20/C5/wKhkA1RJKuyAf6lWAACIJ28IFe8161.png)

如果是使用子域名的话非常简单。在（pages）CNAME文件中填写www.winseliu.com，然后在（net.cn）解析页添加CNAME指向winse.github.io即可。

如果想默认顶级域名也能访问，需要添加的两个ip指向，参见上图。同时（pages）CNAME中使用winseliu.com。

## 参考

* [My custom domain isn't working](https://help.github.com/articles/my-custom-domain-isn-t-working/)
* [Tips for configuring an A record with your DNS provider](https://help.github.com/articles/tips-for-configuring-an-a-record-with-your-dns-provider/)