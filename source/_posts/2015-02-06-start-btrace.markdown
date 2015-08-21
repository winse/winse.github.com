---
layout: post
title: "学习btrace"
date: 2015-02-06 20:38:33 +0800
comments: true
categories: [tools]
---

到官网下载[btrace](https://kenai.com/projects/btrace/downloads/directory/releases)，在btrace-bin.zip压缩包中包括了usersguide.html入门教程。源码用hg管理[点击下载](https://kenai.com/projects/btrace/sources/hg/show)。

Btrace程序是一个普通的java类，由**BTrace annotations**标注的带有的`public static void`方法组成。从代码上面来看，类似于spring aop的写法。标注用于指定需要监控的位置（方法，类）。

Btrace程序是只读的，以及只能执行有限制的操作。一般的限制：

* 不能创建新对象（new objects）
* 不能创建数组（new arrays）
* 不能抛出异常（throw）
* 不能捕获异常（catch）
* 不能调用实例/静态方法。仅仅能调用com.sun.btrace.BTraceUtils的static方法。
* 不能给被监测的程序的实例或者静态字段复制。但是Btrace程序可以给自己的类的静态字段复制。
* 不能有实例字段和方法。Btrace类中仅能包括static字段和`public static void`的方法。
* 不能有内部类，嵌套类（outer, inner, nested or local classes）
* 不能有同步块或同步方法
* 不能包括循环（for，while，do...while）
* 不能继承（父类只能是默认的java.lang.Object）
* 不能实现接口
* 不能包括assert语句
* 不能使用类常量

## helloworld

```
// import all BTrace annotations
import com.sun.btrace.annotations.*;
// import statics from BTraceUtils class
import static com.sun.btrace.BTraceUtils.*;

// @BTrace annotation tells that this is a BTrace program
@BTrace
public class HelloWorld {
 
    // @OnMethod annotation tells where to probe.
    // In this example, we are interested in entry 
    // into the Thread.start() method. 
    @OnMethod(
        clazz="java.lang.Thread",
        method="start"
    )
    public static void func() {
        // println is defined in BTraceUtils
        // you can only call the static methods of BTraceUtils
        println("about to start a thread!");
    }
}
```

通过命令行脚本`btrace <PID> <btrace-script>`脚本运行。script可以是java源文件，或者已经编译好的class字节码文件。

btracec提供了类似于javac的功能，额外会对include的文件中定义的变量进行替换。如果你的btrace类就是一个普通功能的java类的话，直接用javac编译及可以了。

编写一个测试类，然后监控这个java程序的线程启动：

```
public class HelloTest {

	@Test
	public void test() throws Exception {
		testNewThread();
	}
	
	public void testNewThread() throws InterruptedException {
		Thread.sleep(20 * 1000); // 最佳方式就是使用Scanner，手动输入一个操作后执行后面的操作。scanner.nextLine()

		for (int i = 0; i < 100; i++) {
			final int index = i;
			new Thread(//
					new Runnable() {
						public void run() {
							System.out.println("my order: " + index);
						}
					} //
			).start();
		}
	}

}
```

然后，启动btrace程序：

```
cd src\test\script

#下面的内容是一个批处理文件
set PATH=%PATH%;C:\cygwin\bin;C:\cygwin\usr\local\bin

set BTRACE_HOME=E:\local\opt\btrace-bin
set CUR_ROOT=%cd%\..\..\..
set SCRIPT=%CUR_ROOT%\src\main\java\com\github\winse\btrace\HelloWorld.java
set SCRIPT=%CUR_ROOT%\target\classes\com\github\winse\btrace\HelloWorld.class

jps -m  | findstr HelloTest | gawk '{print $1}' | xargs -I {} %BTRACE_HOME%\bin\btrace.bat {} %SCRIPT%
```

上面的主程序启动后sleep了20s，等btrace程序启动。如果是程序一启动就要进行监控记录，可vm的参数添加javaagent：

```
-javaagent:E:\local\opt\btrace-bin\build\btrace-agent.jar=noServer=true,scriptOutputFile=C:\Temp\test.txt,script=F:\workspaces\cms_hadoop\btrace\target\classes\com\github\winse\btrace\HelloWorld.class
```

添加到eclipse的运行配置（Debug Configurations）参数（Arguments）的VM arguments输入框内。

启动主程序，就可以在C:\Temp\test.txt文件看到btrace程序输出的内容了。

## 注解

* 参数

@Self获取this对象
@Return用于获取方法的返回值对象
@TargetInstance和@TargetMethodOrField用来查看被监控的方法内部调用那些实例的方法
@ProbeClassName和@ProbeMethodName用来检测获取当前被监控实例和方法（在OnMethod中使用通配符时，查看到底有那些方法被调用）

* 方法

@OnMethod
@OnTimer
@OnError
@OnExist
@OnLowMemory
@OnEvent
@OnProbe

## 源码

* <https://github.com/winse/helloJ/tree/hello/btrace>

