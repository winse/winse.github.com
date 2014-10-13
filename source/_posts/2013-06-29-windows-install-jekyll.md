---
layout: post
title: 在windows操作系统安装jekyll服务
date: 2014-3-13 23:35:32
categories: [jekyll]
---

如果windows安装了**cygwin**，那就不要折腾了，参考本文最后，按照类似linux的安装是最方便简单的了！

## 参考文档：

* [安装 Jekyll](http://chxt6896.github.io/blog/2011/11/30/blog-jekyll-install.html)
* [Development Kit](https://github.com/oneclick/rubyinstaller/wiki/development-kit)
* [解决GEM INSTALL JEKYLL的问题](http://blog.ownlinux.net/2012/08/fix-gem-install-jekyll-problem.html)

我首先把安装过程中参考的链接放上来，下面的操作其实是对他们的一个梳理。

## 下载 & 安装包

* [MsysGit](https://code.google.com/p/msysgit/) Git-1.8.3-preview20130601.exe
* [ruby](http://rubyforge.org/frs/?group_id=167) rubyinstaller-1.9.3-p392.exe
* [rubydev](https://github.com/oneclick/rubyinstaller/downloads/) DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe

安装的路径根据自己的需要进行选择即可。我这里选择的是：

* C:\Program Files\Git
* C:\Ruby193
* C:\rubydev

## 设置环境变量，并初始化安装rubydev

打开git命令窗口(bash命令行)，操作如下：

```
Winseliu@WINSE ~
$ export PATH=/c/Ruby193/bin:/c/rubydev/bin:$PATH

Winseliu@WINSE ~
$ cd /c/rubydev/

Winseliu@WINSE /c/rubydev
$ ruby dk.rb  init
[INFO] found RubyInstaller v1.9.3 at C:/Ruby193

Initialization complete! Please review and modify the auto-generated
'config.yml' file to ensure it contains the root directories to all
of the installed Rubies you want enhanced by the DevKit.

Winseliu@WINSE /c/rubydev
$ ruby dk.rb install
[INFO] Updating convenience notice gem override for 'C:/Ruby193'
[INFO] Installing 'C:/Ruby193/lib/ruby/site_ruby/devkit.rb'
```

## 安装jekyll

安装的过程并非一路顺风，rubygems的官网好像被禁了。需要更新源。
	
```
Winseliu@WINSE /c
$ gem install jekyll
ERROR:  Could not find a valid gem 'jekyll' (>= 0) in any repository
ERROR:  Possible alternatives: jekyll

Winseliu@WINSE /c
$ gem sources --remove http://rubygems.org/
http://rubygems.org/ removed from sources

Winseliu@WINSE /c
$ gem sources -a http://ruby.taobao.org/
http://ruby.taobao.org/ added to sources

Winseliu@WINSE /c
$ gem sources -l
*** CURRENT SOURCES ***

http://ruby.taobao.org/

Winseliu@WINSE /c
$ gem install rack
Fetching: rack-1.5.2.gem (100%)
Successfully installed rack-1.5.2
1 gem installed
Installing ri documentation for rack-1.5.2...
Installing RDoc documentation for rack-1.5.2...
```

## 真正安装jekyll

```
Winseliu@WINSE /c/rubydev
$ gem install jekyll
Temporarily enhancing PATH to include DevKit...
Building native extensions.  This could take a while...
Fetching: classifier-1.3.3.gem (100%)
Fetching: directory_watcher-1.4.1.gem (100%)
Fetching: syntax-1.0.0.gem (100%)
Fetching: maruku-0.6.1.gem (100%)
Fetching: kramdown-1.0.2.gem (100%)
Fetching: yajl-ruby-1.1.0-x86-mingw32.gem (100%)
Fetching: posix-spawn-0.3.6.gem (100%)
Building native extensions.  This could take a while...
Fetching: pygments.rb-0.5.1.gem (100%)
Fetching: highline-1.6.19.gem (100%)
Fetching: commander-4.1.3.gem (100%)
Fetching: safe_yaml-0.7.1.gem (100%)
Fetching: colorator-0.1.gem (100%)
Fetching: jekyll-1.0.3.gem (100%)
Successfully installed fast-stemmer-1.0.2
Successfully installed classifier-1.3.3
Successfully installed directory_watcher-1.4.1
Successfully installed syntax-1.0.0
Successfully installed maruku-0.6.1
Successfully installed kramdown-1.0.2
Successfully installed yajl-ruby-1.1.0-x86-mingw32
Successfully installed posix-spawn-0.3.6
Successfully installed pygments.rb-0.5.1
Successfully installed highline-1.6.19
Successfully installed commander-4.1.3
Successfully installed safe_yaml-0.7.1
Successfully installed colorator-0.1
Successfully installed jekyll-1.0.3
14 gems installed
Installing ri documentation for fast-stemmer-1.0.2...
Installing ri documentation for classifier-1.3.3...
Installing ri documentation for directory_watcher-1.4.1...
Installing ri documentation for syntax-1.0.0...
Installing ri documentation for maruku-0.6.1...
Couldn't find file to include 'MaRuKu.txt' from lib/maruku.rb
Installing ri documentation for kramdown-1.0.2...
Installing ri documentation for yajl-ruby-1.1.0-x86-mingw32...
Installing ri documentation for posix-spawn-0.3.6...
Installing ri documentation for pygments.rb-0.5.1...
Installing ri documentation for highline-1.6.19...
Installing ri documentation for commander-4.1.3...
Installing ri documentation for safe_yaml-0.7.1...
Installing ri documentation for colorator-0.1...
Installing ri documentation for jekyll-1.0.3...
Installing RDoc documentation for fast-stemmer-1.0.2...
Installing RDoc documentation for classifier-1.3.3...
Installing RDoc documentation for directory_watcher-1.4.1...
Installing RDoc documentation for syntax-1.0.0...
Installing RDoc documentation for maruku-0.6.1...
Couldn't find file to include 'MaRuKu.txt' from lib/maruku.rb
Installing RDoc documentation for kramdown-1.0.2...
Installing RDoc documentation for yajl-ruby-1.1.0-x86-mingw32...
Installing RDoc documentation for posix-spawn-0.3.6...
Installing RDoc documentation for pygments.rb-0.5.1...
Installing RDoc documentation for highline-1.6.19...
Installing RDoc documentation for commander-4.1.3...
Installing RDoc documentation for safe_yaml-0.7.1...
Installing RDoc documentation for colorator-0.1...
Installing RDoc documentation for jekyll-1.0.3...
```	

## 创建新博客

（2014年3月19日更新 Cygwin）

**建立新的本地测试文件夹**

```
Administrator@winseliu /cygdrive/c/Users/Administrator/target
$ rm -rf export

Administrator@winseliu /cygdrive/c/Users/Administrator/target
$ jekyll new export
New jekyll site installed in /cygdrive/c/Users/Administrator/target/export.

Administrator@winseliu /cygdrive/c/Users/Administrator/target
$ cd export/

```

**修改配置_config.yml**

```
name: Your New Jekyll Site
markdown: rdiscount
pygments: false

```

**启动服务**

```
Administrator@winseliu /cygdrive/c/Users/Administrator/target/export
$ jekyll serve --trace -w -P 8000
Configuration file: /cygdrive/c/Users/Administrator/target/export/_config.yml
            Source: /cygdrive/c/Users/Administrator/target/export
       Destination: /cygdrive/c/Users/Administrator/target/export/_site
      Generating... done.
 Auto-regeneration: enabled
[Listen warning]:
  Listen will be polling for changes. Learn more at https://github.com/guard/listen#polling-fallback.

    Server address: http://0.0.0.0:8000
  Server running... press ctrl-c to stop.

```

## 注意点

### 出现编码问题

参考：<http://www.duzengqiang.com/blog/post/979.html>

文件在对应的文件夹下：
C:\Ruby193\lib\ruby\gems\1.9.1\gems\jekyll-1.0.3\lib\jekyll\convertible.rb

```
-        self.content = File.read(File.join(base, name))
+        self.content = File.read(File.join(base, name), :encoding=>"utf-8")
```

（2014-3-13更新）重装系统后，jekyll-1.3.1版本的代码不同了，修改如下：

```
	def read_yaml(base, name, opts = {:encoding=>"utf-8"})
      begin
```

***OR***

<http://www.dewen.org/q/5893>

>
要指定文件的编码格式
在文件开头加上
` # -*- coding:utf-8 -*- `
>	
指定运行环境的编码
使用
` ruby --encoding=utf-8 `
>

**启动**： 

```
Winseliu@WINSE ~
$ cd /c/Users/Winseliu/Documents/GitHub/winse.github.com/

Winseliu@WINSE ~/Documents/GitHub/winse.github.com (master)
$ jekyll serve --trace -w
```

然后访问 <http://localhost:4000> 即可。

**本地调试**

* ruby使用`puts`输出，可以用来打印调试！
* 在本地免不了要写一些**中文名的文件**，可以直接增加try-catch（post.rb#self.valid, cleaner.rb#existing_files）！但网上有讲ruby2.0可以处理中文文件名了！
* 当然本地调试可以通过**修改`_config.xml`的exclude**排除掉，修改好需要发布时再修改为英文文件名即可！

post.rb

```
    def self.valid?(name)
begin
      name =~ MATCHER
rescue => err
  puts err
  puts name
end
    end

```

### 编写文件头需要注意的地方；

[诡异的jekyll空格](http://cache.baiducontent.com/c?m=9f65cb4a8c8507ed4fece763105392230e54f733779c954228c3933fc239045c0535b6ec3a5d1219b2c176631cab4358e8f43d6537747af1c4969c0f80fbc42777df7e7f2e429141639144ee8d5124b137902dfeae69a7eae733e3b9d3a0c85523cd58127af1abd74d00659133ab526ab0f8c200424810cbaa6c33a80d2c75c87557b636a6b774345ad7e1dd2d16906bc7606180a841a73f62ec44ef&p=8973d716d9c106ff57ee96744c53a5&newp=8349d103929a12a05abd9b7d0f1c8f231615d70e3fd3d111&user=baidu&fm=sc&query=jekyll++post%2Erb%3A59+in+initialize+undefined+method+has_key&qid=&p1=1)

>忽然想起之前看过的一篇博客，这篇文章中说起“YAML格局默认是：参数＋：＋空格，若是忘怀写空格描画编译报错。”。  
在这里，恰是因为忘怀了空格导致了HTML文件无法生成的题目。

### maruku的不足

使用rdiscount ( `gem install rdiscount` ) 替换。

+ [Jekyll对中文问题的处理](http://nepshi.com/2012-10-08/chinese-characters-in-jekyll/)
+ [Jekyll本地调试之若干问题](http://chxt6896.github.io/blog/2012/02/13/blog-jekyll-native.html)

## 参考

* <http://chxt6896.github.io/blog/2012/02/13/blog-jekyll-native.html>

- - - - -

# WINDOW直接在cygwin中安装jekyll

1. 使用cygwin setup.exe安装ruby1.9（安装2.0的报编码的错），以及libyaml，最好也把git安装一下。配置环境变量。
2. 使用`gem install jekyll`安装。
3. 安装依赖`gem install rdiscount`。
4. 启动`jekyll serve --trace -w`。

由于cygwin下默认是utf8编码，并且已经有了linux的各种命令，安装起来很简单。

