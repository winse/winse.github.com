---
layout: post
title: 使用Jekyll建立自己的博客
date: 2013-05-24 20:20
categories: [jekyll]
---

本来在sinaapp上面有弄过一阵子的blog，但是sina是需要￥的，没过一阵就没有币了。后面也就不了了之的。  
偶然的机会，看到在github上面可以写自己的blog。同时也挺好奇，看到过一些blog的页面的源文件的md（markdown）后缀到底是干嘛的？

于是与，自己也准备弄来玩玩，感觉也挺不错的。

## 安装

### 建立Blog

<http://jekyllbootstrap.com/index.html#start-now>  

* 首先在自己的github上面建立一个名为USERNAME.github.com（我这里就是winse.github.com)。
* 获取一个模板（有点类似与Demo的意思），我们可以在这个基础之上再来修改。

```
 $ git clone https://github.com/plusjade/jekyll-bootstrap.git winse.github.com
 $ cd winse.github.com
 $ git remote set-url origin git@github.com:winse/winse.github.com.git
 $ git push origin master
```

* 等待一段时间后，就可以访问http://winse.github.com来查看自己的pages github了。

### 本地环境搭建

作为程序员，我们也许想自己本来也能搭建一个环境，自己查看ok后再上传到github上面。  
<http://jekyllbootstrap.com/usage/jekyll-quick-start.html>

本来想在window上面实现的，但是总是报错。但是在linux上分分钟就搞定了。就先在linux上面搭建一个用用先。

```
sudo apt-get install ruby
sudo gem install jekyll

cd winse.github.com
jekyll serve

http://localhost:4000
```

其实，步骤是很简单的，但是windows依赖的环境让人很纠结！

## 如何编写自己的blog

```
rake post title="Hello World"
rake page name="about.md"
rake page name="pages/about.md"
rake page name="pages/about"
```

接下来，就可以通过[markdown]的格式来编写自己的blog了。注意格式哦，*另存为*的时刻选择编码**UTF8-无BOM**！！

## 学习案例

* [mytharcher.github.com](https://github.com/mytharcher/mytharcher.github.com)
* <http://tekkub.net/>
* [README.textile](https://github.com/mojombo/jekyll/blob/master/README.textile)

## 参考

* <http://docs.shopify.com/themes/liquid-basics/output>
* <http://jekyllrb.com/docs/variables/>
* <http://hi.baidu.com/pluto632/item/5007737da31344326f29f666>
* <http://msdn.microsoft.com/en-us/library/aa767914(VS.85).aspx>
* <http://stackoverflow.com/questions/636381/what-is-the-best-way-to-do-a-substring-in-a-batch-file>
