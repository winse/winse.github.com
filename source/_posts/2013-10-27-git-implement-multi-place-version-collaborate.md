---
layout: post
title: Git实现多地多版本协作
date: 2013-10-27 20:20
categories: [tools, git]
---

## 具体情况：

* 网络的版本库 github.com/winse/winse.github.com
* 笔记本       /d/winsegit/winse.github.com/
* U盘          /?/works/winse.github.com  (盘符会变化)

想实现：以笔记本电脑上的更新为主，辅之U盘上的修改（上班时可能进行更新）。

使用SVN基本没法实现这种功能的。原来也没有深入的学习git，看了《Git权威指南》后豁然开朗！

* **Git允许一个版本库和任意多个的版本库进行交互** （第十九章 远程版本库）
* Git本地库即可以作为客户端，也可以作为其他库的服务端！

## 实际操作

* 把笔记本的*winse.github.com*程序拷贝到U盘中
* 为U盘的版本库添加远程版本库notebook
* U盘版本库建立新分支
* U盘修改提交并push到远程版本库notebook
* 笔记本的版本库把新分支merge到master

第一步也可以直接使用`git clone /d/winsegit/winse.github.com/`，后面添加github网络的远程版本库remote-repo就是了。

## 命令

U盘数据更新提交到笔记本

	$ git branch usb
	$ git checkout usb
	$ git add *got-git*
	$ git commit -m definitive-guide-of-git
	
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git remote add notebook /d/winsegit/winse.github.com/
	
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git fetch notebook
	From d:/winsegit/winse.github.com
	 * [new branch]      master     -> notebook/master
	
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git remote
	notebook
	origin
	
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git  branch -r
	  notebook/master
	  origin/HEAD -> origin/master
	  origin/master
	
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git push notebook usb
	Counting objects: 8, done.
	Delta compression using up to 2 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (5/5), 490 bytes | 0 bytes/s, done.
	Total 5 (delta 1), reused 0 (delta 0)
	To d:/winsegit/winse.github.com/
	 * [new branch]      usb -> usb

笔记本合并U盘提交的数据

	Winseliu@WINSE /d/winsegit/winse.github.com (master)
	$ git branch
	* master
	  usb
	
	Winseliu@WINSE /d/winsegit/winse.github.com (master)
	$ git cherry usb
	
	Winseliu@WINSE /d/winsegit/winse.github.com (master)
	$ git merge usb
	Updating 9f7dff3..31ffaa9
	Fast-forward
	 bookreview/_posts/2013-10-27-got-git-the-definitive-guide-of-git.md | 5 +++++
	 1 file changed, 5 insertions(+)
	 create mode 100644 bookreview/_posts/2013-10-27-got-git-the-definitive-guide-of-git.md

U盘重新获取笔记本的数据合并到usb分支 
 
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git fetch notebook
	From d:/winsegit/winse.github.com
	   9f7dff3..31ffaa9  master     -> notebook/master
	
	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git merge master
	Already up-to-date.

## 其他实践命令

远程版本库中包含的分支

	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git ls-remote --heads /d/winsegit/winse.github.com
	9f7dff396b357ca23e1cd765a6dae4ade3417e15        refs/heads/master

查看远程分支

	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git branch -r
	  new-remote/master
	  origin/HEAD -> origin/master
	  origin/master

添加的远程版本库重命名

	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git remote rename new-remote notebook

Git查看远程库路径

	Administrator@WINSELIU /e/git/hello-clone (master)
	$ git remote -v
	origin  e:/git/hello (fetch)
	origin  e:/git/hello (push)
	
查看全部的本地引用

	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git show-ref
	9f7dff396b357ca23e1cd765a6dae4ade3417e15 refs/heads/master
	31ffaa98d45eaccf8f9d0949fc1d4375f36f9edb refs/heads/usb
	06f6c285b7402fb23a50ccb929b7cd84d98028e7 refs/remotes/origin/HEAD
	06f6c285b7402fb23a50ccb929b7cd84d98028e7 refs/remotes/origin/master

查看哪些提交领先（未被推送到上游跟踪分支中）

	Winseliu@WINSE /i/works/winse.github.com (usb)
	$ git cherry master
	+ 31ffaa98d45eaccf8f9d0949fc1d4375f36f9edb

各种引用ID之间转换

	Winseliu@WINSE /d/winsegit/winse.github.com (master)
	$ git rev-parse usb master
	31ffaa98d45eaccf8f9d0949fc1d4375f36f9edb
	9f7dff396b357ca23e1cd765a6dae4ade3417e15
