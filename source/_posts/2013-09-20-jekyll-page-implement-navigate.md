---
layout: post
title: "Jekyll页面实现上/下一篇文章导航"
date: 2014-3-14 0:03:23
categories: [jekyll]
---

在博客页面在内容会有上一遍和下一遍文章的链接。
在jekyll的page对象包含上下篇的引用 [Template Data Api](http://jekyllbootstrap.com/api/template-data-api.html) ，只需要在页面进行展示即可。

默认主题中jekyll-bootstrap的twitter主题中包含上下篇文章的实现如下：

{% raw %}

	<hr>
	<div class="pagination">
	  <ul>
	  {% if page.previous %}
		<li class="prev"><a href="{{ BASE_PATH }}{{ page.previous.url }}" title="{{ page.previous.title }}">&larr; Previous</a></li>
	  {% else %}
		<li class="prev disabled"><a>&larr; Previous</a></li>
	  {% endif %}
		<li><a href="{{ BASE_PATH }}{{ site.JB.archive_path }}">Archive</a></li>
	  {% if page.next %}
		<li class="next"><a href="{{ BASE_PATH }}{{ page.next.url }}" title="{{ page.next.title }}">Next &rarr;</a></li>
	  {% else %}
		<li class="next disabled"><a>Next &rarr;</a>
	  {% endif %}
	  </ul>
	</div>
	<hr>

{% endraw %}   


**注意点**

```
{ % highlight % }{ % endhighlight % }

# 用于直接输出liquid标签源码，但是raw不能嵌套使用
{ % raw % } { % endraw % }
```

## 参考

* [liquid-date output](http://docs.shopify.com/themes/liquid-basics/output#date)
* [日期格式化](http://joshbranchaud.com/blog/2012/12/24/Date-Formatting-in-Jekyll.html)
* [使用Jekyll在Github上搭建个人博客](http://blog.segmentfault.com/skyinlayer/1190000000406013)
* [分页](http://blog.segmentfault.com/skyinlayer/1190000000406015)
* [旧blog迁移到jekyll+github](http://jser.me/2013/07/28/%E6%97%A7blog%E8%BF%81%E7%A7%BB%E5%88%B0jekyll%2Bgithub.html)
* [jekyll可以使用的参数](http://jekyllrb.com/docs/variables/)
* [liquid页面渲染语言](https://github.com/shopify/liquid/wiki/liquid-for-designers)
* [javascript-liquid](http://www.open-open.com/lib/view/open1361323129134.html)
