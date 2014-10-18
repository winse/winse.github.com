---
layout: post
title: GIT操作记录手册
date: 2014-3-30 14:15:11
categories: [tools, git, recommend]
---

Git的每次提交都有一个**唯一的ID**与之对应，所有的TAG/Branch/Master/HEAD等等，都是一个**软链接/别名**而已！这个是理解好Git的基础！

## 提交最佳实践

* commit 只改一件事情。
* 如果一个文档有多个变更，使用`git add --patch`只选择文档中的**部分变更**进入stage。具体怎么使用，键入命令后在输入`?`
* 写清楚 commit message

## 配置

### 内建的图形化 git：

```
gitk
```

### git服务器

搭建git服务器也很方便，有很多web-server的版本，我试用了下[scm-manager](http://www.scm-manager.org/download/)使用挺简单的！
如果已经有了SVN的服务器，可以直接使用git-svn检出到本地！！

### 配置环境

```
git config --global user.email "XXX"
git config --global user.name "XXX"
```

### 换行（\r\n）提交检出均不转换

基本上都在windows操作系统上工作，不需要进行转换！

```
git config --global core.autocrlf false
```

* true 提交时转换为LF，检出时转换为CRLF
* input 提交时转换为LF，检出时不转换
* false 提交检出均不转换

### core.safecrlf

* true 拒绝提交包含混合换行符的文件
* false 允许提交包含混合换行符的文件
* warn 提交包含混合换行符的文件时给出警告

### 默认分支

.git/config如下的内容：

```
[branch "master"]
    remote = origin
    merge = refs/heads/master
```

这等于告诉git两件事:
1. 当你处于master branch, 默认的remote就是origin。
2. 当你在master branch上使用git pull时，没有指定remote和branch，那么git就会采用默认的remote（也就是origin）来merge在master branch上所有的改变

如果不想或者不会编辑config文件的话，可以在bush上输入如下命令行：

```
$ git config branch.master.remote origin 
$ git config branch.master.merge refs/heads/master 
```

之后再重新git pull下。最后git push你的代码，到此步顺利完成时，则可以在Github上看到你新建的仓库以及你提交到仓库中文件了OK。

### 修改默认Git编辑器

```
$ git config core.editor vim

$ git config --global core.editor vi
```

## 常用基本操作

| 操作                                          | 说明                                                  
|:-------------------------------------------- -|:-------------------------------------------------------
| git init                                      | 
| git init --bare                               | 服务端使用bare（空架子，赤裸）的方式
| git status                                    | 使用git打的最多的就是status命令，查看状态的同时会提示下一步的操作！
| git diff                                      | 工作空间和index/stage进行对比
| git diff --cached                             | index/stage与本地仓库进行对比
|**增加到变更(index/stage)**                    | 
| git add .                                     | 将当前目录添加到git仓库中，常用命令！
| git add -A                                    | 添加所有改动的文档
| git add -u                                    | 只加修改过的文件,新增的文件不加入
| git rm --cached <file>...                     | 
|**添加到本地库**                               | 
| git commit                                    | 
| git commit -m "msg"                           | 
| git commit -a                                 | -a是把所有的修改的（tracked）文件都commit
| git commit --amend -m "commit message."       | 未push到远程分支的提交，快捷的回退再提交。修补提交（修补最近一次的提交而不创建新的提交），可结合git add使用！
| git commit -v                                 | -v 可以看到文件哪些内容被修改
| git commit -m 'v1.2.0-final' --allow-empty    |
| git reset                                     | 
| git reset HEAD^                               | 
| git reset --hard HEAD^                        | 
| git checkout file                             | 
| git checkout --orphan <branchname>; git rm --cached -r . |
| git rebase                                    | 
| git merge                                     | 
|**日志**                                       | 
| git log                                       | 
| git log --oneline --decorate --graph          | 
| git log --stat                                | 查看提交信息及更新的文件
| git log --stat -p -1 --format=raw             | 
| git log -3 <file-name>                        | 文件的最近3次提交的历史版本记录
| git log --stat -2                             | 查看最近两次的提交描述及修改文件信息
| git log -p -2                                 | 展开显示每次提交的内容差异，类似git show功能
| git log --name-status                         | 仅显示文件的D/M/A的状态
| git log --summary                             | 
| git log --dirstat -5                          | 
| git log --pretty=format:"%h %s" --graph       | 
| git log --pretty=oneline                      | 
| git reflog                                    | 查看本地操作历史。 ref log
| git show                                      | 查看某版本文件的内容，版本库中最新提交的diff！
| git show master:index.md                      | 查看历史版本的文件内容
| git show <哈希值:文件目录/文件>               | 查看内容
| git cat-file                                  | 
|**分支**                                       | 
| git branch                                    | 查看本地分支
| git branch <branch>                           | 添加新分支，新分支创建后不会自动切换！！
| git branch --set-upstream branch-name origin/branch-name      | * 建立本地分支和远程分支的关联
| git branch -a                                 | 
| git branch --list --merged                    | 
| git branch -r                                 | 查看远程分支
| git checkout --orphan <new-branch>            | 
| git checkout <branch>                         | 切换分支
| git checkout -b [new_branch_name]             | 创建新分支并立即切换到新分支。git checkout -b branch-name origin/branch-name，本地和远程分支的名称最好一致
| git branch -d branch_name                     | -d选项只能删除已经参与了合并的分支，对于未有合并的分支是无法删除的。如果想强制删除一个分支，可以使用-D选项
| git branch -d -r remote_name/branch_name      | 
| git merge origin/local-branch                 | 本地分支与主分支合并
|**推/拉**                                      |
| git pull                                      | * 等价于git fetch && git merge
| git fetch                                     | 先把git的东西fetch到你本地然后merge后再push
| git push --rebase                             | * 
| git push                                      | 
| git push --set-upstream origin <branch>       | To push the current branch and set the remote as upstream
| git push origin branch-name                   | 创建远程分支(本地分支push到远程)，从本地推送分支。如果推送失败，先用git pull抓取远程的新提交
| git push -u origin master                     | 将代码从本地回传到仓库
| git push origin test:master                   | 提交本地test分支作为远程的master分支
| git push -f                                   | * 强推(--force)，即利用强覆盖方式用你本地的代码替代git仓库内的内容，这种方式不建议使用。
| git pull [remoteName] [localBranchName]       | 获取远程版本库提交与本地提交进行合并
| git push [remoteName] [localBranchName]       | 提交、推送远程仓库
| git push --tags                               | 提交时带上标签信息
| git push <git-url> master                     | 把本地仓库提交到远程仓库的master分支中
| git push origin :branch_name                  | 删除远端分支,(如果:左边的分支为空，那么将删除:右边的远程的分支。)远程的test将被删除，但是本地还会保存的，不用担心。
| git push origin :/refs/tags/tagname           | 删除远端标签
| git clone http://path/to/git.git              | clone的内容会放在当前目录下的新目录
| git clone --branch <remote-branch> <git-url>  | 获取指定分支，检出远程版本的分支。 git clone --branch unity /d/winsegit/hello helloclone
|**TAG**                                        | 
| git tag                                       | 查看标签
| git tag <tag>                                 | 添加标签
| git tag -d <tag>                              | 删除标签
| git tag -r                                    | 查看远程标签
| git show <tag>                                | 查看标签的信息
| git tag -a <tag> <msg>                        | 
|**REMOTE**                                     | 
| git remote [show]                             | 查看远程仓库
| git remote -v                                 | 查看远程仓库
| git remote add [name] [url]                   | 添加远程仓库
| git remote set-url --push[name][newUrl]       | 修改远程仓库
| git remote show origin                        | 远程库origin的详细信息。缺省值推送分支，有哪些远端分支还没有同步到本地，哪些已同步到本地的远端分支在远端服务器上已被删除，git pull 时将自动合并哪些分支！
| git remote show <remote-name>                 | 远程版本信息查看
| git remote add origin <git-url>               | 设置仓库
| git remote rm [name]                          | 删除远程仓库
|**文件列表**                                   |
|git ls-tree --name-only  -rt <SHA-ID>
|**打包**                                       | 
| git archive --format tar --output <tar> master| 将 master以tar格式打包到指定文件

## 按功能点完整的操作步骤

### 查看指定版本文件内容

```
Administrator@WINSELIU /e/git/hello (master)
$ git ls-tree master
100644 blob 139b30f9054cf77bd2eeabcebaf6ca3f32cd1d50    abc

Administrator@WINSELIU /e/git/hello (master)
$ git cat-file -p 139b30f9054cf77bd2eeabcebaf6ca3f32cd1d50
```

### 查看提交版本的指定文件内容

```
git log abc  # 获取文件提交ID
git cat-file -p <commit-id>  # 获取treeID
git cat-file -p <tree-id>  # 获取当前tree的列表
git cat-file -p <file-blob-id>
```

### 根据格式输出日志

```
$ git log --pretty=oneline
$ git log --pretty=short
$ git log --pretty=format:'%h was %an, %ar, message: %s'
$ git log --pretty=format:'%h : %s' --graph
$ git log --pretty=format:'%h : %s' --topo-order --graph
$ git log --pretty=format:'%h : %s' --date-order --graph
```

你也可用‘medium','full','fuller','email' 或‘raw'. 如果这些格式不完全符合你的相求， 你也可以用‘--pretty=format'参数(参见：git log)来创建你自己的"格式“.

### 本地提交后再次修改

**修改注释**

```
git commit --amend 
```

**内容修改**

```
 # edit file
git add file
git commit --amend
```

**提交了不该提交的，并撤回**

刚刚提交的不完整，想修改一些东西，加到刚才的提交中

commit -> modify -> add -> amend

```
git reset HEAD^
git status
cat abc
git diff
git commit -a -m "for test reset"
git log
git diff

vi abc
git add abc
git commit --amend

git status
git diff
git show master:abc
git log
```

### 没有push到远程库的提交，本地可以做的事情

* git reset: 用于回溯，回到原来的提交节点，多次提交合并为一个
* git rebase <origin>：在origin分支的基础上，合并当前分支上的提交，形成线性提交历史。 会把当前分支的提交保存为patch，然后切到origin分支应用patch，形成线性的提交，common-origin-current。

rebase冲突处理时，使用git add && git rebase --continue。如果你使用了git add && git commit，那么当前冲突使用git rebase --skip即可。

### 处理本地和服务器之间冲突的方式

* 以本地为主。 git push -f
* 归并merge。 git pull 或者 git fetch && git merge
* 

从stash恢复出现冲突，可以先提交，然后在pop，最后处理冲突。一般提交到本地index中的数据才是自己想要的，从stash中获取的数据只是临时的，可以直接用HEAD的数据内容覆盖，省去处理冲突的时间。

```
$ git add -u
$ git commit -m 'update XXXX'
$ git stash pop

$ git status | grep 'both modified'  | grep ' ssh-config' | awk -F: '{print $2}' | while read line ; do git show HEAD:"$line" > "$line" ; done

```

### 从Github远程服务上拿其他分支： 

```
Administrator@WINSELIU /e/git/to-markdown (master)
$ git branch -r
  origin/HEAD -> origin/master
  origin/gh-pages
  origin/jquery
  origin/master

$ git checkout -b jquery origin/jquery
```

### 把本地的git项目发布到Github

```
touch README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin git@github.com:winse/flickr-uploader.git
git push -u origin master
```

Push an existing repository from the command line：

```
git remote add origin git@github.com:winse/flickr-uploader.git
git push -u origin master
```

如果已经存在remote origin，使用下面的方式修改远程的地址：

```
Administrator@WINSELIU /d/winsegit/flickr_uploader/chrome (master)
$ git remote set-url --add origin  git@github.com:winse/flickr-uploader.git

Administrator@WINSELIU /d/winsegit/flickr_uploader/chrome (master)
$ git remote show origin
Warning: Permanently added 'github.com,192.30.252.128' (RSA) to the list of known hosts.
* remote origin
  Fetch URL: git@github.com:winse/flickr-uploader.git
  Push  URL: git@github.com:winse/flickr-uploader.git
  HEAD branch: (unknown)
```

### git查看本地领先远程的提交

```
Administrator@WINSELIU /d/winsegit/winse.github.com (master)
$ git status
# On branch master
# Your branch is ahead of 'origin/master' by 2 commits.
#   (use "git push" to publish your local commits)
#
# Changes not staged for commit:
#   (use "git add <file>..." to update what will be committed)
#   (use "git checkout -- <file>..." to discard changes in working directory)
#
#       modified:   about.md
#       modified:   blog/_posts/2014-01-21-monitoring-mobile-networks.md
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#
#       default.html
no changes added to commit (use "git add" and/or "git commit -a")

Administrator@WINSELIU /d/winsegit/winse.github.com (master)
$ git log --oneline --decorate -5
0425ec5 (HEAD, master) 增加日志Github修改历史功能
f3a4a58 把TAG定位到首页，并分页以及按照年分类
d5097e3 (origin/master, origin/HEAD) plugins disabled in github page!
e75d62b test
876dd42 修复根目录下的md不能通过npp-windows请求编辑的BUG

Administrator@WINSELIU /d/winsegit/winse.github.com (master)
$ git cherry
+ f3a4a58cfead3aa76e4b92de3342bee5970accb7
+ 0425ec548aa4e3dd29cd6fbfa1b656543e85058e
```

### 找回游离的提交

**绑定到新分支**

```
git reflog # 查看本地操作历史
git branch head23 HEAD@{23} # 把分支head23指向/绑定到游离的提交
```

git的版本都是从分支开始查找的，如果没有被分支管理的提交就游离在版本库中！
所以在reset重新修改时，最好建立分支然后再提交！
如果发现类似的提交问题，就需要尽快的修复，不然提交的ID找不到就S了！

>
那些老的提交会被丢弃。 如果运行垃圾收集命令(pruning garbage collection), 这些被丢弃的提交就会删除. （请查看 git gc)
>

**重置HEAD**

```
git reset --hard HEAD@{23}
```

### 删除提交

删除提交E：

```
$ git tag F
$ git tag E HEAD^
$ git tag D HEAD^^
$ git checkout D
$ git cherry-pick master # 把master-patch应用到TAG-D
# fix conflicts
$ git status # 提交
$ git checkout master # checkout到master分支
$ git reset --hard HEAD@{1} # 重置master到删除E后的提交

```

### Git浏览特定版本的文件列表

```
git ls-tree --name-only  -rt <SHA-ID>
```

### 删除没有被git track的文件

```
git clean -fd # -f force branch switch/ignore unmerged entries， -d if you have new directory
git clean -x -fd

git reset --hard ( or git reset then back to 1. )
git checkout . ( or specify with file names )
git reset --hard ( or git reset then back to 3. )
```

### 检出SVN项目

```
Administrator@ZGC-20130605LYE /e/git
$ git svn clone http://chrome-hosts-manager.googlecode.com/svn/trunk/
```

<http://www.worldhello.net/2010/02/01/339.html>下面提到的有意思：
 
>Git-svn 是 Subversion 的最佳伴侣，可以用 Git 来操作 Subversion 版本库。这带来一个非常有意思的副产品——部分检出：
可以用 git-svn 来对 Subversion 代码库的任何目录进行克隆，克隆出来的是一个git版本库
可以在部分克隆的版本库中用 Git 进行本地提交。
部分克隆版本库中的本地提交可以提交到上游 Subversion 版本库的相应目录中 

### Github添加项目主页github page(gh-pages)

提交后就可以访问了[页面](http://winse.github.io/flickr-uploader/popup.html)了。

```
Administrator@WINSELIU /d/winsegit/flickr_uploader/chrome (master)
$ git branch -a
* master
  remotes/origin/master

Administrator@WINSELIU /d/winsegit/flickr_uploader/chrome (master)
$ git push origin master:gh-pages
Warning: Permanently added 'github.com,192.30.252.128' (RSA) to the list of known hosts.
Total 0 (delta 0), reused 0 (delta 0)
To git@github.com:winse/flickr-uploader.git
 * [new branch]      master -> gh-pages

Administrator@WINSELIU /d/winsegit/flickr_uploader/chrome (master)
$ git branch -a
* master
  remotes/origin/gh-pages
  remotes/origin/master

```

**[Creating Project Pages manually](https://help.github.com/articles/creating-project-pages-manually)**

>```
>	cd repository
>
>	git checkout --orphan gh-pages
>	# Creates our branch, without any parents (it's an orphan!)
>	# Switched to a new branch 'gh-pages'
>	
>	git rm -rf .
>	# Remove all files from the old working tree
>	# rm '.gitignore'
>	
>	echo "My GitHub Page" > index.html
>	git add index.html
>	git commit -a -m "First pages commit"
>	git push origin gh-pages
>```

### 子模块操作

[git-submodule教程！](http://josephjiang.com/entry.php?id=342)

```
Administrator@WINSELIU /d/winsegit/jae_winse (master)
$ git submodule add git@github.com:winse/flickr-uploader.git src/main/webapp/flickr

Administrator@WINSELIU /d/winsegit/jae_winse (master)
$ git submodule status
 635090c5a754eebf5ce6566b7f8c65446b764f51 src/main/webapp/flickr (heads/master)

Administrator@WINSELIU /d/winsegit/jae_winse (master)
$ git commit -m "add submodule"
[master c7dc8c7] add submodule
warning: LF will be replaced by CRLF in .gitmodules.
The file will have its original line endings in your working directory.
 2 files changed, 4 insertions(+)
 create mode 100644 .gitmodules
 create mode 160000 src/main/webapp/flickr
```

如：$ git submodule add git://github.com/soberh/ui-libs.git src/main/webapp/ui-libs

初始化子模块：$ git submodule init ----只在首次检出仓库时运行一次就行

更新子模块：$ git submodule update ----每次更新或切换分支后都需要运行一下

删除子模块：（分4步走哦）

1. $ git rm --cached [path]
2. 编辑“.gitmodules”文件，将子模块的相关配置节点删除掉
3. 编辑“.git/config”文件，将子模块的相关配置节点删除掉
4. 手动删除子模块残留的目录

## 其他偶尔使用命令

```
git diff --check # 检查行尾有没有多余的空白
git remote prune <remotename>
git ls-remote --heads origin
git gc --prune=now
git ls-remote --heads <remote-name>
git rm -r --cached *
```

## 参考

* [回溯 与 合并:git rebase与git reset](http://blog.csdn.net/trochiluses/article/details/8996431)
* [git教程的一个站点](http://ihower.tw/git/)
* [git基本操作](http://ihower.tw/git/basic.html)
* [版本管理介绍](http://ihower.tw/git/vcs.html)
* [速查表](http://blog.csdn.net/ithomer/article/details/7529841)
* [Git 基础 - 查看提交历史](http://git-scm.com/book/zh/Git-%E5%9F%BA%E7%A1%80-%E6%9F%A5%E7%9C%8B%E6%8F%90%E4%BA%A4%E5%8E%86%E5%8F%B2)
* [查看历史 －Git日志](http://gitbook.liuhui998.com/3_4.html)

* <http://git-scm.com/book/zh/Git-%E5%B7%A5%E5%85%B7-%E9%87%8D%E5%86%99%E5%8E%86%E5%8F%B2>
* <http://ihower.tw/blog/archives/2622>
* <http://git-scm.com/docs/git-rebase>
* <http://xiewenbo.iteye.com/blog/1285693>
* <http://gitready.com/>
* <http://git-scm.com/book/zh/Git-%E5%9F%BA%E7%A1%80-%E6%9F%A5%E7%9C%8B%E6%8F%90%E4%BA%A4%E5%8E%86%E5%8F%B2>
* <http://josephjiang.com/entry.php?id=342> git-submodule没有更好的教程了
* <http://www.cnblogs.com/william9/archive/2012/09/01/2666767.html>
* <http://marklodato.github.io/visual-git-guide/index-zh-cn.html>
* <http://www.16kan.com/question/detail/321093.html>
* <http://gitbook.liuhui998.com/3_4.html>
* <http://www.bootcss.com/p/git-guide/>
* <http://blog.csdn.net/ithomer/article/details/7529022>
* <http://git-scm.com/book/zh/Git-%E5%88%86%E6%94%AF-%E8%BF%9C%E7%A8%8B%E5%88%86%E6%94%AF>
* <http://git-scm.com/book/zh/Git-%E5%9F%BA%E7%A1%80-%E8%BF%9C%E7%A8%8B%E4%BB%93%E5%BA%93%E7%9A%84%E4%BD%BF%E7%94%A8>
* <http://blog.csdn.net/trochiluses/article/details/14517379>

