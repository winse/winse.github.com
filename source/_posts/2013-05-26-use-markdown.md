---
layout: post
title: 编写自己的Page(MarkDown/MD)
date: 2013-05-26 20:20
categories: [jekyll]
---

## 学习参考链接

+ [WIKI](http://en.wikipedia.org/wiki/Markdown)
+ [Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
+ [快速入门\(官网翻译\)](http://wowubuntu.com/markdown/index.html)
+ [Markdown 语法说明 (简体中文版)](http://wowubuntu.com/markdown/basic.html)
+ [Markdown语法说明](http://uliweb.clkg.org/tutorial/view_chapter/32)
+ [怎样使用Markdown](http://www.ituring.com.cn/article/23)
+ [开始使用 Markdown](http://ued.taobao.com/blog/2012/07/getting-started-with-markdown/)
+ <http://daringfireball.net/projects/markdown/syntax>

其实上面的几个链接讲的都比较类似，不过看看都挺好的。

## 笔记

下面这些可以“所见即所得”的编写。同时对于一些不是很方便的，可以直接使用html的标签来实现。

### *斜体*

```
*italic*
_italic_
```

### **加粗**

```
**bold**
__bold__
```

*星号*中不能包括空格！

```
单星号 = *斜体*
单下划线 = _斜体_
双星号 = **加粗**
双下划线 = __加粗__
三星号 = ***粗斜***
三下划线 = ___粗斜___
双波浪线 = ~~中划线~~

尖号 = ^上标文本^
双逗号 = ,,下标文本,,
倒单引号 = `代码`

<u>下划线</u> 效果
上标 H<sub>2</sub>O
下标 mc<sup>2</sup>
```

### [链接](winse.github.com)

* Inline:

```
An [example](http://url.com/ "Title")
```

* Reference-style labels (titles are optional):

```
An [example][id]. Then, anywhere else in the doc, define the link:

	[id]: http://example.com/  "Title"
```

### 图片

* Inline (titles are optional):

```
![alt text](/path/img.jpg "Title")
```

* Reference-style:

```
![alt text][id]

	[id]: /url/to/img.jpg "Title"
```

### 标题

* Setext-style:

```
Header 1
========
	
Header 2
--------
```

* atx-style (closing #'s are optional):

```
# Header 1 #
	
## Header 2 ##
	
#### Header 6
```

### 列表

```
* Ordered, without paragraphs:
	1.  Foo
	2.  Bar
* Unordered, with paragraphs:
	*   A list item.
		
		With multiple paragraphs.
		
	*   Bar
* You can nest them:
	*   Abacus
		* answer
	*   Bubbles
		1.  bunk
		2.  bupkis
			* BELITTLER
		3. burper
	*   Cunning
```

**在列表下的`Code Spans`需要添加额外数目的tab哦！~~并且不能以$开头，前面最好加上个空格！~~**

### Blockquotes

```
> Email-style angle brackets
> are used for blockquotes.
	
> > And, they can be nested.
	
> #### Headers in blockquotes
> 
> * You can quote a list.
> * Etc.
```

### Code Spans

* `<code>` spans are delimited by backticks.

```
You can include literal backticks like `this` .
```

* Preformatted Code Blocks Indent every line of a code block by at **least 4 spaces or 1 tab**.
* 使用GFW可以使用代码块.

### This is a *normal* paragraph.

```
This is a preformatted
code block.
```

### Horizontal Rules

Three or more dashes or asterisks:

```
---
	
* * *
	
- - - - 
```

### Manual Line Breaks

End a line with **two or more spaces**:

```
Roses are red,   
Violets are blue.
```

### GFW

GitHub提供了一些额外的方便的标签支持：

* 换行支持，直接Enter
* 代码块使用` ``` ` 
* 表格支持
* 链接文本会被解析为a


## Transfer

+ <http://dillinger.io/>
+ <http://daringfireball.net/projects/markdown/dingus>
+ <http://softwaremaniacs.org/playground/showdown-highlight>

## 其他声音

[Why I hate markdown \(and prefer reST\)](http://blog.liancheng.info/why-i-hate-markdown/#.UaTHM9JaTYQ)
[GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown)

## Soft

<http://markdownpad.com/>
