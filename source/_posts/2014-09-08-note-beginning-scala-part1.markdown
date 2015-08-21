---
layout: post
title: "【笔记】Beginning Scala（1）"
date: 2014-09-08 07:36:57 +0800
comments: true
categories: [scala, books]
---

Scala借鉴了python、ruby等函数式语言。从java转过来还是需要一个适应阶段，与groovy比似乎困难多了不少。一年前好奇接触过，看了一些官网的入门教程，觉得这就是一个异类，后面就放下了。

直到再次弄hadoop，接触spark。经过一个时间的过渡期后，发现Scala确实能处理java的一些繁琐问题，为我们的双手减负，写出更简洁更优雅的代码，或者说更”易懂“。

**这篇是第一章（About Scala and How to Install It）和第二章（Scala Syntax, Scripts, and Your First Scala Programs）的笔记。**

作者寄语：

> My Path was hard, and I hope yours will be easier.

## 历史与安装

随着HotSpot对JVM的改进，JDK1.3的程序与C++写的程序一样快。Java程序可以运行几个星期、几个月、甚至一年都不用重启。

好的Java代码与C/C++的代码一样快，甚至更快。在同样功能下，经过深度调优的C/C++程序会比Java程序更高效，与C/C++相比Java程序需要更多的内存，但对于一个适度复杂的项目（非系统内核级别），JVM程序将比C/C++表现的更优异。

这么多年来，Java在语言级别还不成熟。Java语法停滞不前，Java上的web框架越来越笨重。处理XML，或者其他一些简单概念的实现，如字段生成前台的HTML表单，需要越来越多的代码。对Java越来越失望。
Java5增加了枚举和泛型，对语言而言这是一个可喜的消息，但编码方面我们不得不使用IDE来完成Java代码编写。

“写Scala”的Martin Odersky曾编写了java编译器和泛型功能。Scala(2001, first version in 2003)，语法表达能力如ruby，但同时有Java的强类型和高性能。

Scala即快又简洁，同时类型安全。Scala运行效率也很高，最终编译成Java字节码跑在JVM上，又能与Java代码互相调用。

> But most importantly, Scala taught me  to program and reason about programming differently. I stopped thinking in terms of allocating buffers, structs, and objects, and of changing those pieces of memory. Instead, I learned to think about most of my programs as transforming input to output. This change in thinking has lead to lower defect rates, more modular code, and more testable code. Scala has also given me the tools to write smaller, more modular units of code and asse mble them together into a whole that is maintainable, yet far more complex than anything that I could write in Java or Ruby for that matter.

下载安装JDK6+配置PATH, [Scala 2.10+](http://scala-lang.org/download/2.10.4.html)下载zip版本的，然后解压就行了。

```
winse@Lenovo-PC /cygdrive/d/scala/bin
$ ls -1
fsc
fsc.bat
scala
scala.bat
scalac
scalac.bat
scaladoc
scaladoc.bat
scalap
scalap.bat

winse@Lenovo-PC /cygdrive/d/scala/bin
$ scala
Welcome to Scala version 2.10.4 (Java HotSpot(TM) Client VM, Java 1.7.0_02).
Type in expressions to have them evaluated.
Type :help for more information.

scala> def fact(n:Int)=1 to n reduceLeft(_*_) // n!
fact: (n: Int)Int

scala> fact(5)
res0: Int = 120
```

## 语法结构，第一个Scala程序

运行程序的三种方式：

* 命令行交互式的REPL（read-eval-print loop)
* shell/cmd脚本
* 编译打包成jar后运行，跟Java一样

### REPL

进入到Scala的bin目录下，双击scala.bat打开。

```
scala> 1+1
res0: Int = 2

scala> res0*8
res1: Int = 16

scala> val x="hello world"
x: String = hello world

scala> var xl=x.length
xl: Int = 11

scala> import java.util._
import java.util._

scala> val d = new Date
d: java.util.Date = Mon Sep 08 09:17:08 CST 2014
```

### 脚本

脚本中无需显示的定义main方法，当你运行脚本时，Scala把整个文件的内容添加到类的main方法中，编译代码，然后运行生成的main方法。你只需在脚本文件中编写scala代码即可。

```
winse@Lenovo-PC ~
$ scala hello.scala
hello world

winse@Lenovo-PC ~
$ cat hello.scala
println("hello world")
```

### 编译后运行

运行方式和javac类似，会生成对应类的字节码class文件。

```
winse@Lenovo-PC ~/scala-hello
$ scalac hello.scala

winse@Lenovo-PC ~/scala-hello
$ ll
total 13
-rwxr-xr-x  1 winse None 2067 Sep  8 09:27 hello$.class
-rwxr-xr-x  1 winse None  704 Sep  8 09:27 hello$delayedInit$body.class
-rwxr-xr-x  1 winse None  921 Sep  8 09:27 hello.class
-rw-r--r--+ 1 winse None   58 Sep  8 09:26 hello.scala

winse@Lenovo-PC ~/scala-hello
$ cat hello.scala
object hello extends App {

  println("hello world")

}

winse@Lenovo-PC ~/scala-hello
$ scala hello
hello world

```

编译器的启动是很耗时的操作，你可以使用fsc（fast Scala Compiler），fsc是单独运行在后台的编译进程。

如果你原有的项目中使用Ant或Maven，scala有对应的插件，可以很容易把Scala集成到项目中。

### First Scala Programs

在Scala，你可以编写像ruby和python脚本语言代码。如输出“hello world”的println方法，封装了System.out.println()。因为太常用了，println被定义在Scala的Predef（预定义成员）中，每个程序都会自动加载，就像java.lang会自动引入到每个java程序一样。

```
println("hello world")

for {i<- 1 to 10}
  println(i)

for {i<- 1 to 10
     j<- 1 to 10}
  println(i*j)

```

99乘法表：

```
scala> for(i<- 1 to 9){
     | for(j<- 1 to i)
     | printf("%s*%s=%2s\t",j,i,i*j);
     |
     | println()
     | }
1*1= 1
1*2= 2  2*2= 4
1*3= 3  2*3= 6  3*3= 9
1*4= 4  2*4= 8  3*4=12  4*4=16
1*5= 5  2*5=10  3*5=15  4*5=20  5*5=25
1*6= 6  2*6=12  3*6=18  4*6=24  5*6=30  6*6=36
1*7= 7  2*7=14  3*7=21  4*7=28  5*7=35  6*7=42  7*7=49
1*8= 8  2*8=16  3*8=24  4*8=32  5*8=40  6*8=48  7*8=56  8*8=64
1*9= 9  2*9=18  3*9=27  4*9=36  5*9=45  6*9=54  7*9=63  8*9=72  9*9=81
```

编写复杂点的程序，可以使用[Scala-IDE](http://scala-ide.org/)。

```
import scala.io._   // like java import scala.io.*

def toInt(in: String): Option[Int] =
	try {
	  Some(Integer.parseInt(in.trim))
	} catch {
	  case e: NumberFormatException => None
	}

def sum(in: Seq[String]) = {
	val ints = in.flatMap(s => toInt(s))
	ints.foldLeft(0)((a, b) => a + b)
}

println("Enter some numbers and press CTRL+C")

val input = Source.fromInputStream(System.in)
val lines = input.getLines.toSeq

println("Sum " + sum(lines))

```

Option是包含一个或零个对象的容器。如果不包含元素，返回的是单例的None。如果包括一个元素，就是新的Some(theElement)的实例。Option是Scala中避免空指针异常（null pointer）和显示进行null检查的处理一种方式。如果是None，一个业务逻辑将应用到0个元素，是Some就应用到一个元素上。

方法没有显示的return语句，默认就是方法“最后”（逻辑上最后执行的）一个语句的返回值。

sum方法的参数Seq是一个trait（类似java interface），是Array，List以机构其他顺序集合的父trait。trait拥有java interface的所有特性，同时traits可以包括方法的实现。你可以混合很多的traits成一个类。Traits除了不能定义有参构造函数外，其他和类一样。trait使得“多重继承”简单化，无需担忧** the diamond problem**（有点类似近亲结婚 ^ v ^）。

如：当BC都实现了M方法，D不知道用谁的M，会有歧义！！

![](http://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Diamond_inheritance.svg/220px-Diamond_inheritance.svg.png)

在Scala中，定义参数分为val和var，val类似于java final，var类似于java的变量定义。对于不变化的变量，定义为val可以减少代码错误几率，进行防御性的编程。

接下来运行程序， 输入一些数字后按CTRL+C结束，就会输出计算的和。

```
E:\local\home\Administrator\scala-hello>scala Sum.scala
Enter some numbers and press CTRL+C
12
23
34
45
Sum 114
终止批处理操作吗(Y/N)?
```

### 基本的语法Basic Syntax

Scala的全部语法和语言的定义可以查看[Scala Language Specification](http://www.scala-lang.org/docu/files/ScalaReference.pdf)

#### 数字、字符串和XML常量

* ; 行结束符可以忽略

* 和Java一样的常量定义
> Integer: 1882, -1
> Boolean: true, false
> Double: 1.0, 1d, 1e3
> Long: 42L
> Float: 78.9f
> Characters: '4', '?', 'z'
> Strings: "Hello World"

* Scala支持多行的字符串
> """Hello
> Multiline
> World"""

* Scala支持XML常量，包括内嵌的Scala代码
>{% raw %}
 <b>Foll</b>
 <ul>{(1 to 3).map(i => <li>{i}</li>)}</ul>
{% endraw %}

#### 包package和import

package定义在源代码非注释的第一行。和java一样。

import则比java的更加灵活。基本的用法使用：

```
import scala.xml._
```

scala中的import可以基于前面的imports语句。如再导入`scala.xml.transform`：

```
import transform._
```

也可以导入一个具体的class和object：

```
import scala.collection.mutable.HashMap
```

一次性倒入一个package下的几个class或object：

```
import scala.collection.immutable.{TreeMap, TreeSet}
```

甚至可以给原有的class或object定义一个别名。

```
import scala.util.parsing.json.{JSON => JsonParser}
```

import可以定义在任何代码块中，并且只会在当前作用域内有效。还可以引入objects的method，相当于java的import static。

```
class Frog {
	import scala.xml._
	def n: NodeSeq = NodeSeq.Empty
}

object Moose {
	def bark = "woof"
}

import Moose._
bark
```

#### Class, Trait和Object

Scala的对象语法和规则比Java的更加复杂。

Scala去掉了一个文件中只能定义一个public类的限制。你想在一个文件里面放n个类都可以，同时文件的名称也没有限制（Java文件名需要和public的类同名）。

Scala中默认访问级别是public的。

```
// scala
class Foo

// java
public class Foo {
}
```

如果构造函数、方法没有参数，可以省略参数列表（即不需要输入括号）。

```
new Foo

new Foo()

class Bar(name: String)

new Bar("Working...")

class Baz(name: String) {
	// constructor code is inline
	if(name == null) throw new Exception("Name is null")
}
```

Scala的trait，和java中的interface类似。同时trait可以包括具体实现的方法，这是一个非常方便的特性，你不必在定义复杂的类继承关系来实现代码的重用，在Scala中，把代码写在trait中即可。Scala traits类似于Ruby mixins

```
trait Dog

class Fizz2(name: String) extends Bar(name) with Dog

trait Cat {
	def meow(): String
}

trait FuzzyCat extends Cat {
	override def meow(): String = "Meeeeeeeeeow"
}

trait OtherThing {
	def hello() = 4
}

class Yep extends FuzzyCat with OtherThing

(new Yep).meow()
(new Yep).hello()
```

Scala中不支持static关键字，可以使用`object`单例对象来实现类似的功能。当object对象第一次访问才会被初始化，在对应的访问域内仅有一个该实例。Scala object还有一个优势，由于是类的实例，所以可以作为方法参数进行传递。

```
object Simple

object OneMethod {
	def myMethod() = "Only One"
}

object Dude extends Yep

object Dude2 extends Yep {
	override def meow() = "Dude looks like a cat"
}

object OtherDude extends Yep {
	def twoMeows(otherparam: Yep) = meow + ", " + otherparam.meow
}

OtherDude.meow // Meeeeeeeeeow
OtherDude.twoMeows(Dude) // Meeeeeeeeeow, Meeeeeeeeeow
OtherDude.twoMeows(Dude2) // Meeeeeeeeeow, Dude looks like a cat

```

如果object嵌套定义在class, trait, object内部的时刻，在其作用域下每个**实例**会创建一个object的单例。

```
class HasYep {
	object myYep extends Yep {
    override def meow = "Moof"
  }
}

(new HasYep).myYep.meow // 每个HasYep实例会有一个单独的myYep
```

同样Classes，Objects，traits也可以嵌套在classes，objects，traits。

```
class HasClass {
	private class MyDude extends FuzzyCat
	def makeOne(): FuzzyCat = new MyDude
}
```

#### 类继承Class Hierarchy

除了方法（method），其他一切都是对象(an instance of a class)。Java的primitives类型在Scala也被当做对象，如int(Int)。当两个Ints相加时，Scala编译器会对字节码进行优化最终和java的两个ints相加时一样的。如果使用了Int的方法hashCode和toString，当primitive类型被用于需要引用类型时(expects an Any)，Scala编译器会对其进行装箱，如把Int值加入到HashMap。

为了保持命名的规范化，即所有类的第一个单词都是大写的。在Scala中的原始类型对应为Int,Long,Double,Float,Boolean,Char,Short,Byte，他们都是AnyVal的子类。java的void对应Unit， 同样是AnyVal的子类。你也可以使用`()`来显示的返回Unit类型实例。

```
val v = ()

List(v) // List[Unit] = List(())
```

`Nothing`是很酷，任何方法返回Nothing，表示它不是正常返回，肯定是抛出了异常。`None`是一个`Option[Nothing]`的实例，它的get方法会返回`Nothing`，也就是说get方法会抛出异常，而不是返回底层的值类型null。

Any是Scala中所有类的基类，想Object在Java中的地位。但是，Nothing/primitives等等，所以需要在Object下面定义Scala的根基类。

AnyVal是Scala中primitives对象的包装类的基类。
AnyRef与Java中的Object类似。`eq`,`ne`,`==`,`!=`这些方法的含义不同。`==`编译后最终调用java的equals方法，如果需要进行对象引用的比较，使用`eq`进行处理。

#### 方法声明

类型推测很强大也很有用，但是需要小心使用，当类型返回类型不明确时，需要显示进行声明。

```
def myMethod(): String = "Moof"

def myOtherMethod() = "Moof" // not have to explicity declare the return type

def foo(a: Int): String = a.toString

def f2(a: Int, b: Boolean): String = if(b) b.toString else "false"

def list[T](p: T): List[T] = p :: Nil

list(1)
list("Hello")

// 可变参数， Seq[Int]
def largest(as: Int*): Int = as.reduceLeft((a,b) => a max b)

largest(1)
largest(2, 3, 99)
largest(33, 22, 33, 22)

def mkString[T](as: T*): String = as.foldLeft("")(_ + _.toString)

def sum[T <: Number](as: T*): Double = as.foldLeft(0d)(_ + _.doubleValue)

```

方法可以定义在**任何方法块**中，除了最外层即classes，traits，objects定义的地方。方法中可以使用当前作用域类的所有的成员。

```
def readLines(br: BufferedReader) = {
	var ret: List[String] = Nil

	def readAll(): Unit = br.readLine match { 
		case null =>
		case s => ret ::= s; readAll()
	}

	readAll()
	ret.reverse
}
```

方法重写和java的不一样，被重写的方法必须带上override的修饰符。重写抽象的方法可以不带override的修饰符。

```
abstract class Base {
	def thing: String
}

class One extends Base {
	def thing = "Moof"
}
```

不带参数的方法和变量可以使用**相同的方式访问**，重写父类方法时可以使用val代替def。

```
class Two extends One {
	override val thing = (new java.util.Date).toString
}

class Three extends One {
	override lazy val thing = super.thing + (new java.util.Date).toString
}
```

#### 变量声明

和声明方法类似，不过关键字使用val, var, lazy val。var
可以在设置值以后再次进行修改，类似于java中的变量。val在运行到该作用域时就初始化。lazy val仅在访问的时刻进行计算一次。

```
var y: String = "Moof"
val x: String = "Moof"
lazy val lz: String = someLongQuery()
```

在编程时，不推荐使用var变量除非一定要用变量。Given that mutability leads to unexpected defects, minimizing mutability in code minimizes mutability-related defects.

Scala类型推测对变量一样有效，在参数类型明确的情况下，定义参数时可以不用指定类型。

```
var y2 = "Moof"
val x2 = "Moof"
```

Scala支持同时接受多个参数值。 If a code block or method returns a Tuple, the Tuple can be assigned to a val variable.

```
val (i1: Int, s1: String) = Pair(33, "Moof")
val (i2, s2) = Pair(43, "Moof")
```

运行的效果如下：

```
scala> val (i2,s2)=Pair(43,"W")
i2: Int = 43
s2: String = W

scala> i2
res0: Int = 43
```

#### 代码块

方法和参数定义都可以定义在单行。

```
def meth9 = "hello world"
```

或者定义在大括号包围的代码块中。代码块可以去嵌套。代码块的返回值是最后一个行的运行结果。

```
def meth3(): String = {"Moof"}
def meth4(): String = {
	val d = new java.util.Date()
	d.toString()
}
```

参数定义同样可以使用代码块，适合于有少量计算的赋值操作。

```
val x3: String = {
	val d = new java.util.Date()
	d.toString()
}
```

#### Call-by-Name

在java中，所有方法是按call-by-reference或者call-by-value（原始类型）调用。也就是说，在调用栈中的参数的值或者引用（AnyRef）会传递给调用者。

Scala提供另一种传递参数给方法（函数）的方式：call-by-name，可以把方法块传给调用者。 Each time the callee accesses the parameter, the code block is executed and the value is calculated. 

Call-by-name容许我们把耗时的操作（但可能不会用到的）当做参数。For example, in a call to the logger you can use call-by-name, and the express to print is only calculated if it’s going to be logged。Call-by-name同样容许我们创建（如while/doWhile）自定义的控制结构。

```
def nano() ={
	println("Getting nano")
	System.nanoTime
}

def delayed(t: => Long) = {
	println("In delayed method")
	println("Param: " + t)
	t
}

scala> delayed(nano())
In delayed method
Getting nano
Param: 198642874346225
Getting nano
res1: Long = 198642875202814

def notDelayed(t: Long) = {
	println("In not delayed method")
	println("Param: " + t)
	t
}

scala> notDelayed(nano)
Getting nano
In not delayed method
Param: 199944029171474
res5: Long = 199944029171474
```

注意println输出的位置和次数。

#### 方法调用


```
instance.method()
instance.method

instance.method(param)
instance method param
```

方法没有参数时可以省略括号。当只有可以参数时，可以省去点和括号。

实际运行效果：

```
scala> "abc" toUpperCase
warning: there were 1 feature warning(s); re-run with -feature for details
res0: String = ABC

scala> "abc".toUpperCase
res1: String = ABC

scala> "abc".charAt 1
<console>:1: error: ';' expected but integer literal found.
       "abc".charAt 1
                    ^

scala> "abc" charAt 1
res2: Char = b

scala> "abc" concat "efg"
res3: String = abcefg

```

Scala允许方法名中包括+/-/*/?， Scala’s dotless method notation creates a syntactically neutral way of invoking methods that are hard-coded operators in Java.

```
scala> 2.1.*(4.3)
res4: Double = 9.03

scala> 2.1 * 4.3
res5: Double = 9.03
```

多参数的方法调用和java一样。

```
instance.method(p1, p2)
```

Scala中的泛型方法，编译器可以进行类型推断。当然你也可以显示的指定类型。

```
instance.method[TypeParam](p1, p2)
```

#### Functions, apply, update, and Compiler Magic

Scala是一门函数语言，也意味着你可以传递函数，可以把函数作为返回值在函数和方法中返回。

函数是一个带有参数和返回值的代码块。
在JVM中是不容许传递代码块的。Scala中使用特定接口的匿名内部类作为函数内部实现。当传递一个函数时，其实就是传递一个特定接口(trait)的对象。

定义函数的trait使用一个参数和一个返回值:

```
Function1[A, B]
```

其中A是参数类型，B是返回值类型。

所有的函数接口都有一个apply的方法，用于函数的调用。

```
Function1.apply(p: A): B
```

Thus, you can define a method that takes a function and invokes the function with the parameter 42:

```
def answer(f: Function1[Int, String]) = f.apply(42)
```

如果（只要）对象包括apply方法，可以省略apply，直接把参数跟在函数名后面。

```
def answer(f: Function1[Int, String]) = f(42)
```

Scala提供的语法糖，在编译时f(42)会编译成f.apply(42)。这样使用可以让代码更简洁漂亮，同时看起来更像函数调用的写法。

更多的语法糖：

```
Function1[Int, String]
Int => String

def answer(f: Int => String) = f(42)
```

这种语法糖适用于所有包括apply方法对象。

```
scala> class Ap {
     | def apply(in: Int) = in.toString
     | }
defined class Ap

scala> new Ap()(44)
res0: String = 44

scala> new Ap(44)
<console>:9: error: too many arguments for constructor Ap: ()Ap
              new Ap(44)
              ^

scala> val a = new Ap
a: Ap = Ap@18258b2

scala> a(44)
res2: String = 44
```

如果类包括update方法，编译解析赋值操作时，会调用两个参数的update方法。


```
scala> class Up {
     | def update(k: Int, v: String) = println("Hey: " + k + " " + v)
     | }
defined class Up

scala> val u = new Up
u: Up = Up@7bfd80

scala> u(33) = "hello"
Hey: 33 hello

scala> class Update {
     | def update(what: String) = println("Singler: " + what)
     | def update(a: Int, b: Int, what: String) = println("2d update")
     | }
defined class Update

scala> val u = new Update
u: Update = Update@4bd4d2

scala> u() = "Foo"
Singler: Foo

scala> u(3,4) = "Howdy"
2d update

```

Scala中Array和HashMap使用update的方式进行设值。使用这种方式我们可以编写和Scala类似特性的库。

Scala的这些特性可以让我们编写更易理解的代码。同时理解Scala的这些语法糖，能更好的与java类库一起协作。

#### Case Classes

Scala has a mechanism for creating classes that have the common stuff filled in. Most of the time, when I define a class, I have to write the toString, hashCode, and equals methods.  These methods are boilerplate. Scala provides the case class mechanism for filling in these blanks as well as support for pattern matching. 

A case class provides the same facilities as a normal class, but the compiler generates toString,  hashCode, and  equals methods (which you can override). 

Case classes can be instantiated without the use of the  new statement. By default, all the parameters in the case class’s constructor become properties on the case class. Here’s how to create a case class:

```
scala> case class Stuff(name: String, age: Int)
defined class Stuff

scala> val s = Stuff("David", 45)
s: Stuff = Stuff(David,45)

scala> s.toString
res0: String = Stuff(David,45)

scala> s == Stuff("David", 45) // == 相当于java中的equals
res1: Boolean = true

scala> s == Stuff("David", 42)
res2: Boolean = false

scala> s.name
res4: String = David

scala> s.age
res5: Int = 45
```

手写case class功能的类：

```
class Stuff(val name: String, val age: Int) {
	override def toString = "Stuff(" + name + "," + age + ")"
	override def hashCode = name.hashCode + age
	override def equals(other: AnyRef) = other match {
		case s: Stuff => this.name == s.name && this.age = s.age
		case _ => false
	}
}

object Stuff {
	def apply(name: String, age: Int) = new Stuff(name, age)
	def unapply(s: Stuff) = Some((s.name, s.age))
}
```

#### Basic Pattern Matching

模式匹配（Pattern matching）可以使用很少的代码编写非常复杂的判断。Scala Pattern matching和Java switch语句类似， but you can test against almost anything, and you can even assign pieces of the matched value to variables. Like everything in Scala, pattern matching is an expression, so it result s in a value that may be assigned or returned. The most basic pattern matching is like Java’s switch, except there is no  break in each case as the cases do not fall through to each other. 

```
44 match {
	case 44 => true
	case _ => false
}
```

可以对String进行match操作，类似于C#。

```
"David" match {
	case "David" => 45
	case "Elwood" => 77
	case _ => 0
}
```

可以多case classes进行模式匹配（pattern match）操作。Case classes提供了非常适合与pattern-matching的语法。下面的例子，用于匹配Stuff的name==David以及age==45的对象。

```
Stuff("David", 45) match {
	case Stuff("David", 45) => true
	case _ => false
}
```

仅匹配名字：

```
Stuff("David", 45) match {
	case Stuff("David", _) => "David"
	case _ => "Other"
}
```

还可以把值提取出来，如把age的值赋给howOld变量：

```
Stuff("David", 45) match {
	case Stuff("David", howOld) => "David, age: " + howOld
	case _ => "Other"
}
```

还可以在pattern和=>之间添加条件。如年龄小于30的返回young David，其他的结果为old David。

```
Stuff("David", 45) match {
	case Stuff("David", age) if age < 30 => "young David"
	case Stuff("David", _) => "old David"
	case _ => "Other"
}
```

Pattern matching还可以根据类型进行匹配：

```
x match {
	case d: java.util.Date => "The date in milliseconds is " + d.getTime
	case u: java.net.URL => "The URL path: " + u.getPath
	case s: String => "String: " + s
	case _ => "Something else"
}
```

如果使用Java代码的话，需要多很多的转换！！

```
if(x instanceof Date) return "The date in milliseconds is " + ((Date)x).getTime();
if(x instanceof URL) return "The URL path: " + ((URL)x).getPath();
if(x instanceof String) return "String: " + ((String)x);
return "Something else"
```

#### if/else and while

while在Scala中比较少用。if/else使用频率高一些，比java的三目赋值操作符（?:）使用频率更高。if和while表达式总是返回Unit（相当于Java的Void）。if/else的返回值更具各个部分表单时类型确定。

```
if(exp) println("yes")

// multiline
if(exp) {
	println("Line one")
	println("Line two")
}

val i: Int = if(exp) 1 else 3

val i: Int = if(exp) 1 
else {
	val j = System.currentTimeMillis
	(j % 100L).toInt
}
```

while executes its code block as long  as its expression evaluates to  true, just like Java. In practice, using recursion, a method calling itself, provides more readab le code and enforces the concept of transforming input to output rather than changing, mutating, variables. Recursive methods can be as efficient as a while loop.

```
while (exp) println("Working...")
while (exp) {
	println("Working...")
}
```

#### for

```
for { i <- 1 to 3} println(i)

for { i <- 1 to 3
		j <- 1 to 3
	} println(i*j)

def isOdd(in: Int) = in % 2 == 1
for {i <- 1 to 5 if ifOdd(i)} println(i)

for {i <- 1 to 5
		j <- 1 to 5 if isOdd(i*j)} println(i*j)

val lst = (1 to 18 by 3).toList
for {i <- lst if isOdd(i)} yield i

for {i <- lst; j <- lst if isOdd(i*j)} yield i*j
```

将在第三章-集合中更详细的讲解for使用方法。

#### throw, try/catch/finally, and synchronized

try/finally的写法和java类似：

```
throw new Exception("Working...")

try{
	throw new Exception("Working...")
} finally {
	println("This will always be printed")
}
```

try/catch的语法不大一样，catch对异常进行了封装，首先它是一个表达式其返回值是一个值；使用case（pattern matched）来匹配异常类型。

```
try {
	file.write(stuff)
} catch {
	case e: java.io.IOException => // handle IO Exception
	case n: NullPointerException => // handle null Exception
}

try { Integer.parseInt("dog") } catch { case _ => 0 } //0
try { Integer.parseInt("44") } catch { case _ => 0 } //44
```

基于对象的同步操作，每个类都自带了synchronized方法。

```
obj.synchronized {
	// do something that needs to be serialized
}
```

不像java有synchronized方法修饰符。在Scala中同步方法定义使用：

```
def foo(): Int = synchronized {
	42
}
```

#### Comments

注释基本上类C的语言都一样，单行`//`、多上`/* ... */`。

在Scala中还可以嵌套的注释。

```
/*
  This is an outer comment
  /* And this comment
     is nested
  */
  Outer comment
*/
```

#### Scala vs Java vs Ruby

**类和实例**

java有原始类型。Scala中操作都是方法调用，所有东西都是对象，无需为了原始类型而进行额外的判断/处理。

```
1.hashCode
2.toString
```

我们可以定义一个方法，传递函数（从一个Int到另一个Int转换操作）。

```
def with42(in: Int => Int) = in(42)
with42( 33 + )
```

在语言级别，如果所有东西都是统一的，在进行编程设计时就会很方便和简单。同时Scala编译时会针对JVM原始类型进行优化，使得scala的代码在效率上非常接近Java。

**Traits, Interfaces, and Mixins**

在java中除了Object对象，其他对象都有一个唯一的父类。Java类可以实现一个或者多个接口（定义实现类必须实现方法的约定）。这是依赖注入和测试mocks，以及其他抽象模式的基础。

Scala使用traits， Traits提供了Java接口拥有的所有特性。同时Traits可以包括方法的实现以及参数的定义。方法实现一次，把所有继承traits的方法混入子类中。

**Object, Static, and Singletons**

在Java中，可以定义类的（静态）方法和属性，提供了访问方法的唯一入口，同时不需要实例化对象。类（静态）属性提供了在JVM中全局共享数据的方式。
Scala提供了类似的机制：Objects。Objects是单例模式的实现。在类加载的时刻实例化该对象。这种方式同样可以共享全局状态。而且，objects也是Scala完全的面向对象的一种体现，objects是一个类的实例，而不是某种类级别的常量（some class-level constant）。可以把objects作为参数来进行传递。

**Functions, Anonymous Inner Class, and  Lambdas/Procs**

The Java construct to pass units of computation as parameters to methods is anonymous inner class. 匿名内部类在Swing UI库非常的常见。在Swing中，许多UI事件处理的接口定义1-2个方法，在编写程序时，实现事件接口的内部类能访问外部类的私有成员数据。

Scala functions对应的就是匿名内部类。Scala functions实现了统一的接口，调用函数时执行接口的apply方法。和Java匿名内部类相比，Scala创建函数的语法更加简洁和优雅。同时，访问本地参数的规则也更加灵活。在Java匿名内部类只能访问final的参数，而Scala functions能访问和修改vars参数。

Scala和Ruby的面向对象模型和函数式编程很相似。同时Scala在访问类库和静态类型方面和Java很类似。Scala博采众长，把Java和Ruby的优点都囊括了。

### 总结

这一章首相讲了安装和运行Scala程序，然后围绕Scala编程的语法结构来展开。下一章讲解Scala的数据类型，使用很少的代码编写功能健壮的程序，同时编码量的减少也能有效的控制bugs的数量。


