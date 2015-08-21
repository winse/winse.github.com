---
layout: post
title: 让敲Shell命令高效起来
date: 2013-09-19 08:44:57 +0800
comments: true
categories: [tools, shell, recommend]
---

在刚上班的时刻，做过程序的部署工作，后面尽管工作中直接接触的机会很少。
但是一直对shell很敬（很牛）畏（太强太多），第一使用起来确实不是看几本书就能用好的，需要经常持久的使用，第二嘛命令太多个不用一段时间基本就忘记了。

来到新公司后，主要是后台代码的开发。尽管和部署挂不上什么关系，但再次遇到总有个想头-原来使用过去查查，算是自己使用linux过程中的一点总结。

## 记住历史，温故而知新

如果说是新人，可以通过历史学习前辈使用的命令。
作为维护人员，可以记录操作的命令，修改原有命令的部分再执行。

| 命令              | 解释                   |
|:------------------|:-----------------------|
| `history`         |  |
| `!!`              | 执行上一条命令 |
| `!blah`           | 执行最近的以 blah 开头的命令，如 !ls |
| `!blah:p`         | 仅打印输出，而不执行 |
| `!$`              | 上一条命令的最后一个参数，与 Alt + . 相同 |
| `!$:p`            | 打印输出 !$ 的内容 |
| `!*`              | 上一条命令的所有参数 |
| `!*:p`            | 打印输出 !* 的内容 |
| `^blah`           | 删除上一条命令中的 blah |
| `^blah^foo`       | 将上一条命令中的 blah 替换为 foo |
| `^blah^foo^`      | 将上一条命令中所有的 blah 都替换为 foo |
|                   | |
| `fc`              | 打开编辑器(vim)编辑上一条命令 |
| `fc 123`          | 编辑命令历史中编号为123的命令 |
| `fc 123 130`      | 编辑命令历史中123-130的八条命令，退出后依次执行 |
| `fc ls`           | 编辑最后一条以ls开头的命令 |
| `fc -s ls=cat ls` | 将最后一条以ls开头的命令中的ls替换成cat，然后执行 |


参考 [bash命令行历史的用法](http://tech.idv2.com/2007/03/27/bash-history-summary/)

## 快捷键

### 快捷方式

当遇到一串很长的路径时，如果每次都输入，尽管有Tab的辅助，但也不是一件烦心的事情。
这时，我们可以根据增加快捷方式/重定位为我们的工作提高效率，减少重复无谓的工作。

	alias datanodelog="less ~/hadoop/logs/hadoop-Winseliu-datanode-WINSE.log"
	alias jobtrackerlog="less ~/hadoop/logs/hadoop-Winseliu-jobtracker-WINSE.log"
	alias tasktrackerlog="less ~/hadoop/logs/hadoop-Winseliu-tasktracker-WINSE.log"

	ln -s /cygdrive/d/groovy-1.8.4/ groovylink

当你去看linux的bash脚本时，你会发现发现ll的命令其实是ls -l的alias的别名而已。
在工作中如果发现很多类似重复的操作，赶紧的把alias用起来的吧！

### 快速定位

| 快捷              | 解释                   |
|:------------------|:-----------------------|
| **编辑命令**          |
| Ctrl + a          | 移到命令行首 |
| Ctrl + e          | 移到命令行尾 |
| Ctrl + f          | 按字符前移（右向） |
| Ctrl + b          | 按字符后移（左向） |
| Alt + f           | 按单词前移（右向） |
| Alt + b           | 按单词后移（左向） |
| Ctrl + xx         | 在命令行首和光标之间移动 |
| Ctrl + u          | 从光标处删除至命令行首 |
| Ctrl + k          | 从光标处删除至命令行尾 |
| Ctrl + w          | 从光标处删除至字首 |
| Alt + d           | 从光标处删除至字尾 |
| Ctrl + d          | 删除光标处的字符 |
| Ctrl + h          | 删除光标前的字符 |
| Ctrl + y          | 粘贴至光标后 |
| Alt + c           | 从光标处更改为首字母大写的单词 |
| Alt + u           | 从光标处更改为全部大写的单词 |
| Alt + l           | 从光标处更改为全部小写的单词 |
| Ctrl + t          | 交换光标处和之前的字符 |
| Alt + t           | 交换光标处和之前的单词 |
| Alt + Backspace   | 与 Ctrl + w 相同类似，分隔符有些差别 |
| **重新执行命令**      | 
| Ctrl + r          | 逆向搜索命令历史 |
| Ctrl + g          | 从历史搜索模式退出 |
| Ctrl + p          | 历史中的上一条命令，感觉不用那么麻烦吧，直接方向键就行了啊！ |
| **控制命令**          |
| Ctrl + l          | 清屏  |
| Ctrl + o          | 执行当前命令，并选择上一条命令 |
| Ctrl + s          | 阻止屏幕输出 |
| Ctrl + q          | 允许屏幕输出 |
| Ctrl + c          | 终止命令 |
| Ctrl + z          | 挂起命令 |

参考 [Bash快捷键，让命令更有效率](http://www.linuxde.net/2011/11/1877.html)

## 使用趁手的工具

看到同事使用WinScp定位到目录上传文件，然后使用Putty进行命令操作，那个辛苦啊，甚是麻烦！
SSH Secure Shell则集成了Putty和WinScp的功能。
更甚者还是用Xmanger的图形化界面: [Windows连接Linux的常用工具](http://books.blog.51cto.com/2600359/1261976) ， [Windows下如何远程连接 Linux](http://www.zhihu.com/question/20376041)

推荐我最爱的SSH工具: `SecureCRT`

SecureCRT不但能满足shell命令，能保存基本上全部的操作过程（Putty操作则和Linux上的终端效果一样）。

> * **选择复制，右键粘贴**的功能也相当高效。
> * 基于zmoden的lrzsz命令能实现**文件的上传和下载**功能。
> * **记住密码**这功能不在话下。
> * 克隆到新窗口中，实现多视图同时编辑。

看到网上说的**Xshell**功能和SecureCRT类似，还支持颜色，并且是开源的没有版权问题！。[Xshell讨论](http://www.zhihu.com/question/20308776)

## 使用具体案例

1. 批量改名加后缀：

```
ls -1 | xargs -i mv {}{,.old}
```

还原：

```
$ ls -1 | while read line ; do mv "$line" "${line%.*}" ; done
```


## 收藏

* [Linux常用命令大全速查备忘](http://www.linuxde.net/2011/12/3252.html)
* [dos2unix](http://space.itpub.net/?uid-8107207-action-viewspace-itemid-474791)
* [11页的命令啊，包括了常用的命令](http://wenku.baidu.com/view/5f41312758fb770bf78a5516.html)
* [Linux系统信息查看命令大全](http://tech.idv2.com/2008/01/11/linux-sysinfo-cmds)
