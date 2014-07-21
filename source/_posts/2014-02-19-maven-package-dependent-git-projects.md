---
layout: post
title: "maven合并打包依赖的git项目"
date: 2014-02-19 09:56
comments: true
categories: [tools]
---

JD的云引擎可以提供一个网站搭建的Java编译发布环境。但是所有源码都要放在下面。
我只是想把JD提供的环境作为一个门面，来展现内容。自己的东西自己管理。（网上解决是使用submodule，强烈推荐看看.[戳](http://josephjiang.com/entry.php?id=342)）

我建了一个源码库flickrUpload在Github上，如果我想把它放到JD的云引擎上运行，需要复制代码然后再提交一次到jd-code。但不想源码版本库分支混乱，并且JD云上仅仅是为了展示，不进行修改。最终实现使用Maven来检出依赖项目，再进行编译打包实现在JD的展示功能。

## 本地环境使用scm和antrun插件，实现先更新依赖源码再打包

### 检出依赖源码库

由于对Maven不太熟悉，首先想到的是额外执行系统的命令。

``` 
<project>
    <profiles>
        <profile>
            <id>win</id>
            <activation>
                <activeByDefault>false</activeByDefault>
                <os>
                    <family>Windows</family>
                </os>
            </activation>
            <properties>
                <flickrUploader>uploader-git-clone.bat</flickrUploader>
            </properties>
        </profile>
        <profile>
            <id>linux</id>
            <activation>
                <activeByDefault>true</activeByDefault>
                <os>
                    <family>Linux</family>
                </os>
            </activation>
            <properties>
                <flickrUploader>uploader-git-clone.sh</flickrUploader>
            </properties>
        </profile>
    </profiles>

    <build>
        <finalName>product</finalName>

        <plugins>
            <plugin>
                <artifactId>maven-war-plugin</artifactId>
                <configuration>
                    <webResources>
                        <resource>
                            <directory>dist</directory>
                        </resource>
                    </webResources>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>1.1.1</version>
                <executions>
                    <execution>
                        <id>some-execution</id>
                        <phase>compile</phase>
                        <goals>
                            <goal>exec</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <executable>${basedir}/script/${flickrUploader}</executable>
                </configuration>
            </plugin>
        </plugins>
    </build>

```

根据profile来配置来判断环境，执行特定的命令（bat/sh）。

* Windows脚本
``` 
# uploader-git-clone.bat
del /s /q /f dist\Hello-World
rmdir /s /q dist\Hello-World
"C:\Program Files\Git\bin\git.exe" clone https://github.com/octocat/Hello-World.git dist\Hello-World
```
* Linux脚本
``` 
# uploader-git-clone.sh
rm -rf dist/Hello-World
git clone https://github.com/octocat/Hello-World.git dist/Hello-World
```

测试在本地window已经能实现自己的要求，能把checkout项目的内容放在了发布包的根目录下面。

执行`mvn package`后的target目录结构如下：
![](http://farm8.staticflickr.com/7371/12624988843_ccce073e1a_o.png)

### 源码库路径重定位

发布时把源码库文件放置到war的根目录下面，有考虑过COPY：如[Copy-maven-plugin](http://evgeny-goldin.com/wiki/Copy-maven-plugin)，还有如下outputDirectory的形式（[参考](http://outofmemory.cn/code-snippet/2547/maven-copy-file-card-usage)）：

> 
> 
> ```
> <project>
>   ...
>   <build>
>     <plugins>
>       <plugin>
>         <artifactId>maven-resources-plugin</artifactId>
>         <version>2.6</version>
>         <executions>
>           <execution>
>             <id>copy-resources</id>
>             <!-- here the phase you need -->
>             <phase>validate</phase>
>             <goals>
>               <goal>copy-resources</goal>
>             </goals>
>             <configuration>
>               <outputDirectory>${basedir}/target/extra-resources</outputDirectory>
>               <resources>          
>                 <resource>
>                   <directory>src/non-packaged-resources</directory>
>                   <filtering>true</filtering>
>                 </resource>
>               </resources>              
>             </configuration>            
>           </execution>
>         </executions>
>       </plugin>
>     </plugins>
>     ...
>   </build>
>   ...
> </project>
> 
> ```
> 
> 

## 最终实现

上面就要解决两个问题：源码检出和资源重定位。

后面发现war可以**包含**特定目录的资源，资源重定位实现就用war的webResources实现了。
同时为了把检出源码的清理工作提取到clean任务下，添加使用antrun插件。同时发现scm插件就实现了检出源码的功能[maven-scm-plugin](http://maven.apache.org/scm/maven-scm-plugin/)。

使用antrun和scm完全使用Maven实现，最终的插件配置如下：

```
    <project>
        <build>
            <finalName>product</finalName>

            <plugins>

                <plugin>
                    <artifactId>maven-antrun-plugin</artifactId>
                    <executions>
                        <execution>
                            <phase>clean</phase>
                            <configuration>
                                <tasks>
                                    <delete includeEmptyDirs="true">
                                        <fileset dir="${scm-dist}" />
                                    </delete>

                                    <mkdir dir="${scm-dist}" />
                                </tasks>
                            </configuration>
                            <goals>
                                <goal>run</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>

                <plugin>
                    <artifactId>maven-scm-plugin</artifactId>
                    <version>1.9</version>
                    <configuration>
                        <skipCheckoutIfExists>true</skipCheckoutIfExists>
                        <checkoutDirectory>${scm-dist}/flikr</checkoutDirectory>
                        <connectionUrl>scm:git:https://github.com/octocat/Hello-World.git</connectionUrl>
                    </configuration>
                    <executions>
                        <execution>
                            <phase>clean</phase>
                            <goals>
                                <goal>checkout</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>

                <plugin>
                    <artifactId>maven-war-plugin</artifactId>
                    <configuration>
                        <webResources>
                            <resource>
                                <directory>${scm-dist}</directory>
                            </resource>
                        </webResources>
                    </configuration>
                </plugin>

            </plugins>
        </build>

        <properties>
            <!-- for scm -->
            <scm-dist>dist</scm-dist>
        </properties>

```

现在使用`mvn clean package`就可以实现先checkout项目再打包发布了。最终效果全部使用maven实现，无需额外考虑平台之间的差异处理。

## JD的云引擎Maven编译不支持scm插件

> 不支持的插件：'maven-scm-plugin' 在pom文件中被发现,编译将终止,请检查并更新代码!

然后部署到云引擎的时刻，发现antrun和scm的插件都不行，exec也不行！
也尝试过submodule，但是邮件JD的回复说是云上引用内部的才有效！

发布到云引擎最终还是用最土的方法，先删除旧的版本库，然后检出，在提交到云引擎的版本库中。

``` 
# flickr-upload-commit.sh
rm -rf src/main/webapp/flickr
git clone git@github.com:winse/flickr-uploader.git src/main/webapp/flickr
rm -rf src/main/webapp/flickr/.git
git add -A && git commit -m "update uploader, please see https://github.com/winse/flickr-uploader" && git push

```

## 其他

* 子模块基本操作命令

> $ git submodule add [git@github.com](mailto:%67%69%74@%67%69%74%68%75%62.%63%6f%6d):josephj/javascript-platform-yui.git static/platform	
> $ git add .gitmodules static/platform	
> $ git submodule init
> 
> $ cd static/platform	
> $ git pull origin master	
> $ cd ../../ 	
> $ git add static/platform 	
> $ git commit -m "static/platform submodule updated"
> 
> $ git submodule init 		
> $ git submodule update
> 
> $ cd static/platform 	
> $ vim README # 做些修改 	
> $ git add README 	
> $ git commit -m "Add comments" 	
> $ git push 	
> $ git add static/platform 	
> $ git commit -m 'Submodule updated 	
> $ git push
> 
> $ git rm --cached [欲移除的目錄] 	
> $ rm -rf [欲移除的目錄] 	
> $ vim .gitmodules 	
> $ vim .git/config 	
> $ git add .gitmodules 	
> $ git commit -m "Remove a submodule" 	
> $ git submodule sync

### 参考

*   [Maven plugin中的lifecycle、phase、goal、mojo概念及作用的理解](http://gavin-chen.iteye.com/blog/336607)
*   [How to use master pom file to checkout all modules of a web application and build all modules](http://stackoverflow.com/questions/9571859/how-to-use-master-pom-file-to-checkout-all-modules-of-a-web-application-and-buil) 这个和我要实现的问题类似
*   [Ant task to run an Ant target only if a file exists?](http://stackoverflow.com/questions/520546/ant-task-to-run-an-ant-target-only-if-a-file-exists)
*   [MAVEN常用插件](http://blog.csdn.net/eg366/article/details/9398681) 牛逼啊！
*   [maven-antrun-plugin skip target if any of two possible conditions holds](http://stackoverflow.com/questions/15021439/maven-antrun-plugin-skip-target-if-any-of-two-possible-conditions-holds)
*   [How to execute tasks conditionally using the maven-antrun-plugin?](http://stackoverflow.com/questions/1971912/how-to-execute-tasks-conditionally-using-the-maven-antrun-plugin)
*   [maven-scm-provider-jgit](http://maven.apache.org/scm-archives/scm-LATEST/maven-scm-providers/maven-scm-providers-git/maven-scm-provider-jgit/)
*   [Git Submodule 的認識與正確使用！](http://josephjiang.com/entry.php?id=342) 非常详尽

* * * 
[【原文地址】](http://winseliu.logdown.com/posts/2014/02/19/using-maven-checkout-dependent-git-projects)
