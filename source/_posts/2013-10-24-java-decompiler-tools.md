---
layout: post
title: java反编译工具使用记录
date: 2013-10-24 20:20
categories: [java]
---

## 工具

* [jad](http://varaneckas.com/jad/)
* [JD-core](http://jd.benow.ca/)
* 参考 <http://zhouliang.pro/2010/06/26/jad/>

## 差异

JD-Core还是比较与时俱进的，对泛型/foreach等新的语法都支持。Jad则只支持到only 45.3(1.1), 46.0 and 47.0(1.3)。    
任何事物都不是完美的，结合两个工具来看反编译后的源码能更好的回归源码的真相。

* JD-Core解析双for循环是存在问题！结合jad可能更好的明白源码。
* 内部类解析**都**不够好，JD-Core相对错误少一些

## 对比

这里就[for循环]/[双层for循环]/[内部类]进行对比。

### 单for循环

**源码**

```
List<String> list = Arrays.asList("abc", "bcd");

public void testForEach() {
	for (String ele : list) { // for编译成字节码后使用iterator的形式
		System.out.println(ele);
	}
}
```

**JD-Core v0.3.5 JD-GUI v0.6.2**

```
List<String> list = Arrays.asList(new String[] { "abc", "bcd" });

public void testForEach() {
for (String ele : this.list)
	System.out.println(ele);
}
```

**Jad v1.5.8e2.**

```
public JavaDecompilerTest()
{
	list = Arrays.asList(new String[] {
		"abc", "bcd"
	});
}

public void testForEach()
{
	String ele;
	for(Iterator iterator = list.iterator(); iterator.hasNext(); System.out.println(ele))
		ele = (String)iterator.next();

}

List list;
```

### 双层for循环

**源码**

```
List<Map<String, String>> list = new ArrayList<Map<String, String>>();
{
	Map<String, String> map = new HashMap<String, String>();
	map.put("12", "23");
	list.add(map);
}

public void testForIndex() {
	for (int i = 0; i < list.size(); i++) {
		Map<String, String> map = list.get(i);
		for (String key : map.keySet())
			System.out.println(map.get(key));
	}
}

public void testForEach() {
	for (Map<String, String> map : list) {
		for (String key : map.keySet())
			System.out.println(map.get(key));
	}
}
```

**JD-Core v0.3.5 JD-GUI v0.6.2**

```
  List<Map<String, String>> list;

  public JavaDecompilerTest2()
  {
	this.list = new ArrayList();

	Map map = new HashMap();
	map.put("12", "23");
	this.list.add(map);
  }

  public void testForIndex() {
	for (int i = 0; i < this.list.size(); i++) {
	  Map map = (Map)this.list.get(i);
	  for (String key : map.keySet())
		System.out.println((String)map.get(key));
	}
  }

  public void testForEach()
  {
	Iterator localIterator2;
	for (Iterator localIterator1 = this.list.iterator(); localIterator1.hasNext(); 
	  localIterator2.hasNext())
	{
	  Map map = (Map)localIterator1.next();
	  localIterator2 = map.keySet().iterator(); continue; String key = (String)localIterator2.next();
	  System.out.println((String)map.get(key));
	}
  }
```

**Jad v1.5.8e2.**

```
public JavaDecompilerTest2()
{
	list = new ArrayList();
	Map map = new HashMap();
	map.put("12", "23");
	list.add(map);
}

public void testForIndex()
{
	for(int i = 0; i < list.size(); i++)
	{
		Map map = (Map)list.get(i);
		String key;
		for(Iterator iterator = map.keySet().iterator(); iterator.hasNext(); System.out.println((String)map.get(key)))
			key = (String)iterator.next();

	}

}

public void testForEach()
{
	for(Iterator iterator = list.iterator(); iterator.hasNext();)
	{
		Map map = (Map)iterator.next();
		String key;
		for(Iterator iterator1 = map.keySet().iterator(); iterator1.hasNext(); System.out.println((String)map.get(key)))
			key = (String)iterator1.next();

	}

}

List list;
```
   
### 内部类

**源码**

```
public class JavaDecompilerTest3 {

	private class Test2 {}
	
	Test2 test = new Test2();
	
}
```

**JD-Core v0.3.5 JD-GUI v0.6.2**

```
public class JavaDecompilerTest3
{
  JavaDecompilerTest3.Test2 test = new JavaDecompilerTest3.Test2(null);

  private class Test2
  {
	private Test2()
	{
	}
  }
}
```

**Jad v1.5.8e2.**

```
public class JavaDecompilerTest3
{
	private class Test2
	{

		final JavaDecompilerTest3 this$0;

		private Test2()
		{
			this$0 = JavaDecompilerTest3.this;
			super();
		}

		Test2(Test2 test2)
		{
			this();
		}
	}


	public JavaDecompilerTest3()
	{
		test = new Test2(null);
	}

	Test2 test;
}
```

## 后记

工具javap可以查看class的方法签名，通过jd-gui和jad可以反编译得到源码，如果代码没有混淆的话，多半就能了解代码的功能了。
