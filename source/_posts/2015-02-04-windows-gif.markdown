---
layout: post
title: "windows gif"
date: 2015-02-04 15:18:20 +0800
comments: true
categories: ["tools"]
---

看到linux上各种录制gif的工具：

```
yum install byzanz

byzanz-record -d 10 -x 0 -y 0 -w 1363 -h 758 byzanz-demo.gif
```

还有各种包装的工具：[mkcast](https://github.com/KeyboardFire/mkcast)

本来想在cygwin中安装byzanz，但是编译需要各种库，最终放弃了。

其实在windows下面，也有很好的gif录制的工具：[LICEcap](http://www.cockos.com/licecap/)

![](/images/blogs/gif-capture-helloworld.gif)

## 参考

* [windows 下有没有什么录制 gif 截屏质量较好的软件可推荐?](http://v2ex.com/t/139035)
* [Ubuntu录制GIF图](http://v5b7.com/other/ubuntu_byzanz.html)