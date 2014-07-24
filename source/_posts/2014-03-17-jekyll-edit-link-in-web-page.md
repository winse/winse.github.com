---
layout: post
title: Jekyll页面添加编辑按钮
date: 2014-3-17 21:56:53
comments: true
categories: [jekyll]
---

近期把其他博客的日志导出成Markdown后导入到自己的blog。想在本地预览后，看到不好的地方就进行修改，想法是美好的，现实是残酷的！**找文件太麻烦**了，定位到了文件夹，还需要找文件。反正就是觉得很不爽！最终通过[自定义URL协议的方式完美的解决](https://gist.github.com/4548d6c182f8162497fa.git)。

### 尝试ActiveXObject

IE下可以通过[ActiveXObject调用本地的程序](http://iask.sina.com.cn/b/8583473.html?sudaref=www.google.com.hk&retcode=0)打开文件。尽管局限于IE，但是如果能实现的话将就下也OK的。
理所当然认为IE下是没有问题，就找chrome下能否执行[ActiveXObject的兼容对象](http://stackoverflow.com/questions/7022568/javascript-activexobject-in-firefox-or-chrome-not-ie)。

在chrome下，没啥很好的替代实现。同时在IE11下，ActiveXObject调用shell对象报[**automation服务器不能创建对象**](http://www.cnblogs.com/dongyongjing/archive/2007/04/18/718629.html)，需要额外开启功能、降低IE的安全性等等，也很麻烦！！

```
function callShellApplication(){
  var objShell = new ActiveXObject("WScript.shell");
  objShell.run('"C:\Program Files (x86)\wkhtmltopdf\wkhtmltopdf.exe" "c:\PDFTestPage.html" "c:\TEST.pdf"');
}
```

### 尝试Flash

有想过使用flash解决，毕竟剪贴板复制功能的`ZeroClipboard.swf`是那么的完美^_^。但是[swf不能执行exe程序](http://www.cnblogs.com/yao/archive/2008/01/02/1022721.html)，没办法只能再寻求其他办法。

### 自定义URL协议

最后看到了[**URL Protocol的实现方式**][baidu-urlprotocol]，是的哦，Github-Windows、以及QQ等这些网页的工具不都是调用系统的程序吗？！

然后试着按照网页的教程，试着弄弄！~~又是一个新鲜事物，有挑战的事情做起来就更有激情！~~

添加注册表项`reg-npp-windows.bat`：（可以先导出github-windows的注册表项参考。这里使用用bat来实现，注册脚本中可以通过**相对路径**指向执行的程序）

```
set NPP_APP=%~dp0npp-windows.bat
set NPP_ARG=%%1

set "NPP_CMD=\"%NPP_APP%\" \"%NPP_ARG%\""

reg add "HKEY_CLASSES_ROOT\npp-windows" /f
reg add "HKEY_CLASSES_ROOT\npp-windows" /ve /t REG_SZ /d "URL:npp-windows Protocol" /f
reg add "HKEY_CLASSES_ROOT\npp-windows" /v "URL Protocol" /t REG_SZ /d "" /f

reg add "HKEY_CLASSES_ROOT\npp-windows\DefaultIcon"  /f
reg add "HKEY_CLASSES_ROOT\npp-windows\DefaultIcon"  /ve /t REG_SZ /d "" /f

reg add "HKEY_CLASSES_ROOT\npp-windows\shell" /f
reg add "HKEY_CLASSES_ROOT\npp-windows\shell\open" /f
reg add "HKEY_CLASSES_ROOT\npp-windows\shell\open\command" /f
reg add "HKEY_CLASSES_ROOT\npp-windows\shell\open\command" /ve /t REG_SZ /d "%NPP_CMD%" /f

pause

```

点击URL真正调用的是`npp-windows.bat`命令（即上面的注册脚本的`NPP_APP`）:

```
@echo off

set fileRelativePath=%1
set filepath="%~dp0..\..\..\%fileRelativePath:~17,-1%"

start D:\local\usr\npp\notepad++.exe %filepath%
exit

```

`start`命令新起一个子进程打开程序，这样可以启动后面的程序，同时关闭/退出掉黑窗口！
请求参数有整个url加上双引号，如`"npp-windows://e/about.md"`。数字`17,-1`获取真正的路径。由于根下的文件会被自动加反斜杠`"npp-windows://about.md/"`，所以加上`e/`进行修复。

在网页使用链接，然后加上`npp-windows`的协议就可以打开文件进行修改编辑了。

{% raw %}
	<a class="shellExecuteLink" href="npp-windows://e/{{ page.path }}" title="本地编辑"><i class="icon-edit"> </i></a>
{% endraw %}

对BAT的命令相当的迷惑：

* `"D:\local\usr\npp\notepad++.exe" "%~dp0..\..\..\%fileRelativePath:~17,-1%"` OK
* `start D:\local\usr\npp\notepad++.exe "%~dp0..\..\..\%fileRelativePath:~17,-1%"` OK 
* `start "D:\local\usr\npp\notepad++.exe" "%~dp0..\..\..\%fileRelativePath:~17,-1%"` 弹出**Windows无法打开此文件**的框

### 闪黑窗口优化尝试

功能已经实现了，但是仍然有一个黑窗口一闪而过！ 

爱折腾的程序员啊！！

找啊找，发现**vbs可以后台执行命令**。直接在命令行是可以执行**npp-windows.vbs**的，同时那种不弹窗的效果也是自己想要的！！但把vbs作为url-protocol协议的执行程序时，点击页面链接却没一点反应！但是运行bat和exe程序是没有问题的。

其实windows下的bat和vbs程序都是可以转成exe的。
下载了[ScriptCryptor Compiler](http://www.abyssmedia.com/scriptcryptor/)[破解版](http://www.sdbeta.com/uploads/soft/131002/1-131002113S7.rar)，把vbs转成exe后就可以被url-protocol调用了，且没有闪窗的现象了！

```
Dim CurrPath
CurrPath=WScript.Createobject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path

Dim fileRelativePath
fileRelativePath=WScript.Arguments(0)

Dim filepath
filepath=Mid(fileRelativePath,17)

Dim Wsh
Set Wsh = WScript.CreateObject("WScript.Shell")

Wsh.Run "D:\local\usr\npp\notepad++.exe " + CurrPath + "\..\..\..\" + filepath,0,True

Set Wsh=NoThing
WScript.quit

```

同时上面的vbs程序有一个与bat同样的问题：在**文件**没有关闭的前，vbs程序是一直等待的！如果使用这种方式，编辑很多文件就会存在很多进程。

而直接在`Wsh.Run`后面加上`start`前缀就报**系统找不到指定的文件**的错误！整来整去最后还是调用bat文件，解决主进程一直等待的问题。

```
Dim CurrPath
CurrPath=WScript.Createobject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path

Dim fileRelativePath
fileRelativePath=WScript.Arguments(0)

Dim Wsh
Set Wsh = WScript.CreateObject("WScript.Shell")

Wsh.Run CurrPath + "\npp-windows.bat """ + fileRelativePath + """",0,True

Set Wsh=NoThing
WScript.quit

```

然后修改**添加注册表项的命令**reg-npp-windows.bat，重新覆盖注册下就可以了。

```
set NPP_APP=%~dp0npp-windows.vbs.exe
```

尽管没有黑窗口了闪现，但是速度慢了很多！！
两种方式换着用呗，修改也简单： 改下程序的名字，重新注册下就行了。

## 其他

URL-protocol的用户选择设置会被chrome缓冲，可以通过`C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Local State`文件的`protocol_handler`节点来修改。

## 参考

* [Using a WScript.shell activeX to execute a command line](http://stackoverflow.com/questions/15351508/using-a-wscript-shell-activex-to-execute-a-command-line)
* [在html中利用WScript.Shell启用本地程序](http://huagenli.iteye.com/blog/552447)
* [通过网页链接打开应用程序客户端的两种实现方式](http://blog.csdn.net/insidekernel/article/details/2033175)
* [浏览器打开本地程序，全面支持ie,firefox,opera,chrome,自定义url protocol][baidu-urlprotocol]
* [自定义URL Protocol调用Winfrom程序（exe）并实现传值——类似网页链接调用QQ、旺旺](http://blog.csdn.net/lockelk/article/details/7541374)
* [自定义URL Protocol Handler](http://www.cnblogs.com/zjneter/archive/2008/01/08/1030066.html)


[baidu-urlprotocol]: http://hi.baidu.com/pluto632/item/5007737da31344326f29f666
