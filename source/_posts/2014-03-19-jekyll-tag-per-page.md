---
layout: post
title: Jekyll按照tag分页面
date: 2014-3-19 22:21:36
comments: true
categories: [jekyll]
---

## 单页实现

从jekll-bootstrap检出的代码中，`tags.html`实现了标签的显示。但是所有的标签和日志列表都码在一个文件里面，总感觉有点太拥挤。

{% raw %}

	<div class="page-header">
		<h1>{{ page.title }} {% if page.tagline %} <small>{{ page.tagline }}</small>{% endif %}</h1>
	</div>

	<ul class="tag_box inline">
		{% assign tags_list = site.tags %}  
		
		{% if tags_list.first[0] == null %}
			{% for tag in tags_list %} 
			<li><a href="#{{ tag }}-ref">{{ tag }} <span>{{ site.tags[tag].size }}</span></a></li>
			{% endfor %}
		{% else %}
			{% for tag in tags_list %} 
			<li><a href="#{{ tag[0] }}-ref">{{ tag[0] }} <span>{{ tag[1].size }}</span></a></li>
			{% endfor %}
		{% endif %}
		
		{% assign tags_list = nil %}
	</ul>

	{% for tag in site.tags %} 
	<h2 id="{{ tag[0] }}-ref">{{ tag[0] }}</h2>
	<ul class="index">
		{% assign pages_list = tag[1] %}  

		{% if site.JB.pages_list.provider == "custom" %}
			{% include custom/pages_list %}
		{% else %}
			{% for node in pages_list %}
				{% if node.title != null %}
					{% if group == null or group == node.group %}
						{% if page.url == node.url %}
						<li class="active">
							<a href="{{ BASE_PATH }}{{ node.url }}" class="active">{{ node.title | xml_escape }}</a>
							<span><time datetime="{{ node.date | date: "%Y-%m-%d" }}">{{ node.date | date: "%Y/%m/%d" }}</time></span>
						</li>
						{% else %}
						<li>
							<a href="{{ BASE_PATH }}{{ node.url }}" class="active">{{ node.title | xml_escape }}</a>
							<span><time datetime="{{ node.date | date: "%Y-%m-%d" }}">{{ node.date | date: "%Y/%m/%d" }}</time></span>
						</li>
						{% endif %}
					{% endif %}
				{% endif %}
			{% endfor %}
		{% endif %}
		
		{% assign pages_list = nil %}
		{% assign group = nil %}   
	</ul>
	{% endfor %}

{% endraw %}

## 插件实现分页面

找了一些资料，使用plugin的方式可以生成文件，以及页面的自定义标签。在`_plugins`目录下新增`jekyll-tag-page.rb` :

```
module Jekyll

	class TagPage < Page
		def initialize(site, base, dir, tag)
			@site = site
			@base = base
			@dir = dir
			@name = 'index.html'

			self.process(@name)
			self.read_yaml(File.join(base, '_layouts'), 'tag_index.html')

			self.data['tags'] = tag
		end
	end

	class TagPageGenerator < Generator
		safe true

		def generate(site)
			if site.layouts.key? 'tag_index'
				dir = site.config['tag_dir'] || 'tags'
				site.tags.keys.each do |tag|
					site.pages << TagPage.new(site, site.source, File.join(dir, tag), tag)
				end
			end
		end
	end
end

```

生成插件为每个TAG生成了一个页面，`_layout`模板设置为tag_index.html，在模板中可以根据当前页面的tags过滤并只显示该tag的日志列表。文件默认保存到`tags/TAG`目录下。

{% raw %}

	{% for tag in site.tags %} 
		{% if page.tags == tag[0] %}
		<h2>{{ tag[0] }}</h2>
		<ul class="index">
			{% assign pages_list = tag[1] %}  

			{% for node in pages_list %}
				{% if node.title != null %}
				<li>
					<a href="{{ BASE_PATH }}{{ node.url }}">{{ node.title | xml_escape }}</a>
					<span><time datetime="{{ node.date | date: "%Y-%m-%d" }}">{{ node.date | date: "%Y/%m/%d" }}</time></span>
				</li>
				{% endif %}
			{% endfor %}
			
			{% assign pages_list = nil %}
		</ul>
		{% endif %}
	{% endfor %}

{% endraw %}

## 使用脚本生成目录和md文件来实现

但是由于github不支持自定义插件功能，也就是说，就算我提交了`_plugin`的代码也是无效的。**最终最后的实现**，使用Shell脚本在tags目录下生成文件夹和内容：

```
cd $tools/../tags

find * -type d -exec rm -rf {} +

for tag in `cat tags`; do 
mkdir $tag
cat > $tag/index.md <<EOF
---
layout: tag
categories: [$tag]
---

EOF
done;

```

脚本列表tags文件内容生成目录和index.md文件。

layout模板tag.html页面代码如下：

{% raw %}

	<h3>Tag: {{ page.categories[-1] }}</h3>
	<ul class="archive-list">

	{% for tag in site.tags %}
	{% if page.categories[-1] == tag[0] %}

	{% assign pages_list = tag[1] %} 
	{% for node in pages_list %}
		{% if node.title != null %}
			<li class="archive">
				<span>
					<time datetime="{{ node.date | date: "%Y-%m-%d" }}">
						{{ node.date | date: "%Y/%m/%d" }}
					</time>
				</span>
				<a href="{{ BASE_PATH }}{{ node.url }}" class="archive-link">{{ node.title | xml_escape }}</a>
			</li>
		{% endif %}
	{% endfor %}
	{% assign pages_list = nil %} 

	{% endif %}
	{% endfor %}

	</ul>

{% endraw %}

--END

# 参考

* [liquid页面渲染语言](https://github.com/shopify/liquid/wiki/liquid-for-designers)
