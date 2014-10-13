---
layout: post
title: 处理git冲突
time: 2014-3-13 22:08:44
comments: true
categories: [git]
---

## 命令行处理Git冲突

```
# 首先需要修改冲突的文件，整合两个版本的数据！
$ vi _posts/2013-5-26-markdown-stu.md

Winseliu@WINSE ~/Documents/GitHub/winse.github.com ((171a4ea...)|REBASE)
$ git status
# Not currently on any branch.
# You are currently rebasing.
#   (fix conflicts and then run "git rebase --continue")
#   (use "git rebase --skip" to skip this patch)
#   (use "git rebase --abort" to check out the original branch)
#
# Unmerged paths:
#   (use "git reset HEAD <file>..." to unstage)
#   (use "git add <file>..." to mark resolution)
#
#       both added:         _posts/2013-5-26-init-blog-pages.md
#       both added:         _posts/2013-5-26-markdown-stu.md
#
no changes added to commit (use "git add" and/or "git commit -a")

Winseliu@WINSE ~/Documents/GitHub/winse.github.com ((171a4ea...)|REBASE)
$ git rebase --continue
_posts/2013-5-26-init-blog-pages.md: needs merge
_posts/2013-5-26-markdown-stu.md: needs merge
You must edit all merge conflicts and then
mark them as resolved using git add

Winseliu@WINSE ~/Documents/GitHub/winse.github.com ((171a4ea...)|REBASE)
$ git add _posts/2013-5-26-init-blog-pages.md

Winseliu@WINSE ~/Documents/GitHub/winse.github.com ((171a4ea...)|REBASE)
$ git add _posts/2013-5-26-markdown-stu.md

Winseliu@WINSE ~/Documents/GitHub/winse.github.com ((171a4ea...)|REBASE)
$ git rebase --continue
Applying: hello

```

## 问题处理

更新时，与本地未提交的内容冲突。

```
$ git pull
Updating ae0a812..fe592a0
error: Your local changes to the following files would be overwritten by merge:
        eshore/DTA/ISMI_CU/DTA/trunk/README.md
Please, commit your changes or stash them before you can merge.
Aborting
```

处理方法一，把变更先保存到stash，更新后再还原：

```
git stash
git pull
git stash pop
// 然后可以使用git diff -w +文件名 来确认代码自动合并的情况.
```

处理方法二，先提交，然后再更新处理冲突：

```
winse@Lenovo-PC ~/eshore/git
$ git add  eshore/DTA/ISMI_CU/DTA/trunk/README.md

winse@Lenovo-PC ~/eshore/git
$ git commit -m 'start  v1.0.5.5'
[master e95b61c] start  v1.0.5.5
 1 files changed, 10 insertions(+), 0 deletions(-)

winse@Lenovo-PC ~/eshore/git
$ git pull
// 没有冲突直接更新ok了！
```

## Eclipse中处理Github冲突

该链接图文并茂的介绍了处理的方法 <http://jerry-chen.iteye.com/blog/1726022>	。

1. 工程->Team->同步    
2. 从远程pull至本地，会把远程的修改和本地的修改合并到一个文件    
3. 使用Merge Tool，执行第二项。使用HEAD合并后的效果    
4. 再手动修改冲突    
5. 修改后的文件需要添加到git index中去    
6. 冲突文件变为修改图标样式，再提交至本地，此时的提交便是merge合并     
7. 现在可以直接push到远程了    

## 参考

* [Git:代码冲突常见解决方法](http://blog.csdn.net/iefreer/article/details/7679631)