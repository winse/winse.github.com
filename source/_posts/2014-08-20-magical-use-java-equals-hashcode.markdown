---
layout: post
title: "巧用Equals和Hashcode"
date: 2014-08-20 11:03:54 +0800
comments: true
categories: [java]
---

java中让人疑惑的一点就是等于的判断，有使用`==`和`equals`， 有一些专门字符串初始化的资料来考你在是否已经真正的掌握判断两个对象是否一致。

同时，在重写equals时很多资料都强调要重写hashcode。

java中HashMap就是基于equals和hashcode来实现拉链的键值对。Map中存储了entry<K,V>的数组，数组的下标是基于对象的hashcode再对entry长度[并]`&`的结果。

![](http://file.bmob.cn/M00/08/55/wKhkA1P0OO-AE9u3AABNzQK0pr8747.png)

使用set/map来实现集合，并且对象重写了equals但没有重写hashcode的情况下，得到的结果与你臆想的不同。同时，在特定场景结合hashcode和equals可以实现很酷的效果。

* 第一个例子A 重写了equals但是没有重写hashcode(ERROR)，此时判断元素是否在集合中结果可能并不是你想要的。
* 第二个B的例子 重写hashcode和equals对应后就正确了。
* 第三个AA是个很酷的例子 equals的条件更强，可以实现类似`map<string, list<string>>`的效果。

```
	static class A {

		String name;
		int age;

		public A(String name, int age) {
			this.name = name;
			this.age = age;
		}

		@Override
		public boolean equals(Object obj) {
			return new EqualsBuilder().append(getClass(), obj.getClass()).append(name, ((A) obj).name).isEquals();
		}

	}

	@Test
	public void testA() {
		Set<A> set = new HashSet<>();

		set.add(new A("abc", 12));
		set.add(new A("abc", 14));

		System.out.println(set.size());

		System.out.println(set.contains(new A("abc", 0)));
	}

	static class B extends A {

		public B(String name, int age) {
			super(name, age);
		}

		@Override
		public int hashCode() {
			return this.name.hashCode();
		}
	}

	@Test
	public void testB() {
		/* Set<A> */Set<B> set = new HashSet<>();

		set.add(new B("abc", 12));
		set.add(new B("abc", 14));

		System.out.println(set.size());

		System.out.println(set.contains(new B("abc", 0)));
	}

	static class AA extends A {
		public AA(String name, int age) {
			super(name, age);
		}

		@Override
		public boolean equals(Object obj) {
			return new EqualsBuilder().append(getClass(), obj.getClass()).append(name, ((A) obj).name)
					.append(age, ((A) obj).age).isEquals();
		}

		@Override
		public int hashCode() {
			return this.name.hashCode();
		}
	}
	
	@Test
	public void testAA() {
		// 实现Map<String, Set<String>>的效果
		Set<AA> set = new HashSet<>();

		set.add(new AA("abc", 12));
		set.add(new AA("abc", 14));

		System.out.println(set.size());

		System.out.println(set.contains(new AA("abc", 0)));
	}
```

## 参考

* [java中HashMap详解](http://java.chinaitlab.com/base/879319.html)
