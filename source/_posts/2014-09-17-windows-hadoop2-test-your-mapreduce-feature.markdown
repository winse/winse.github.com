---
layout: post
title: "在windows开发测试mapreduce几种方式"
date: 2014-09-17 12:55:38 +0800
comments: true
categories: [hadoop]
---

hadoop提供的两大组件HDFS、MapReduce。其中HDFS提供了丰富的API，最重要的有类似shell的脚本进行操作。而编写程序，要很方便的调试测试，其实是一件比较麻烦和繁琐的事情。

首先可能针对拆分的功能进行**单独的方法**级别的单元测试，然后到map/reduce的一个**完整的处理过程**的测试，再就是针对**整个MR**的测试，前面说的都是在IDE中完成后，最后需要到**测试环境**对其进行验证。

* 单独的方法这里就不必多讲，直接使用eclipse自带的junit即可完成。
* mrunit，针对map/reduce的测试，以至于整个MR流程的测试，但是mrunit的输入是针对小数据量的。
* 本地模式运行程序，模拟正式的环境来进行测试，数据直接从hdfs获取。
* 测试环境远程调试，尽管经过前面的步骤可能还会遇到各种问题，此时可结合`remote debug`来定位问题。

### mrunit测试map/reduce

首先去到[官网下载](http://mrunit.apache.org/)，把对应的jar加入到你项目的依赖。懒得去手工下载的话直接使用maven。

```
	<dependency>
		<groupId>org.apache.mrunit</groupId>
		<artifactId>mrunit</artifactId>
		<version>1.1.0</version>
		<classifier>hadoop2</classifier>
		<scope>test</scope>
	</dependency>
```

可以对mapreduce的各种情况（map/reduce/map-reduce/map-combine-reduce）进行简单的测试，验证逻辑上是否存在问题。[官方文档的例子](https://cwiki.apache.org/confluence/display/MRUNIT/MRUnit+Tutorial)已经很具体详细了。

先新建初始化driver（MapDriver/ReduceDriver/MapReduceDriver)，然后添加配置配置信息（configuration），再指定withInput来进行输入数据，和withOutput对应的输出数据。运行调用runTest方法就会模拟mr的整个运行机制来对单条的记录进行处理。因为都是在一个jvm中执行，调试是很方便的。

```
	private MapReduceDriver<LongWritable, Text, KeyWrapper, ValueWrapper, Text, Text> mrDriver;

	@Before
	public void setUp() {
		AccessLogMapper mapper = new AccessLogMapper();
		AccessLogReducer reducer = new AccessLogReducer();
		// AccessLogCombiner combiner = new AccessLogCombiner();

		mrDriver = MapReduceDriver.newMapReduceDriver(mapper, reducer);

		// mDriver = MapDriver.newMapDriver(mapper);
		// mcrDriver = MapReduceDriver.newMapReduceDriver(mapper, reducer, combiner);
	}

	private String[] datas;

	@After
	public void run() throws IOException {
		if (datas != null) {
			// 配置
			...
			mrDriver.setConfiguration(config);
			// mrDriver.getConfiguration().addResource("job_1399189058775_0627_conf.xml");

		  // 输入输出
			Text input = new Text();
			int i = 0;
			for (String data : datas) {
				input.set(data);
				mrDriver.withInput(new LongWritable(++i), new Text(data));
			}
			mrDriver.withOutputFormat(MultipleFileOutputFormat.class, TextInputFormat.class);
			mrDriver.runTest();
		}
	}

	// / datas

	private String[] datas() {
		return ...;
	}

	@Test
	public void testOne() throws IOException {
		datas = new String[] { datas()[0] };
	}
```

## local方式进行本地测试

mapreduce默认提供了两种任务框架： local和yarn。YARN环境需要把程序发布到nodemanager上去运行，对于开发测试来讲，还是太繁琐了。

使用local的方式，既不用打包同时拥有IDE本地调试的便利，同时数据直接从HDFS中获取，也就是说，除了任务框架不同，其他都一样，程序的输入输出，任务代码的业务逻辑。为全面开发调试/测试提供了极其重要的方式。

只需要指定服务为local的服务框架，再加上输入输出即可。如果本地用户和hdfs的用户不同，设置下环境变量`HADOOP_USER_NAME`。同样map、reduce通过线程来模拟，都运行的同一个JVM中，断点调试也很方便。

```
public class WordCountTest {
	
	static {
		System.setProperty("HADOOP_USER_NAME", "hadoop");
	}
	
	private static final String HDFS_SERVER = "hdfs://umcc97-44:9000";

	@Test
	public void test() throws Exception {
		WordCount.main(new String[]{
				"-Dmapreduce.framework.name=local", 
				"-Dfs.defaultFS=" + HDFS_SERVER, 
				HDFS_SERVER + "/user/hadoop/dta/001.tar.gz", 
				HDFS_SERVER + "/user/hadoop/output/"});
	}

}

```

### 测试环境打包测试

放到测试环境后，appmanager、map、reduce都是运行在不同的jvm；还有就是需要对程序进行打包，挺啰嗦而且麻烦的事情，依赖包多的话，包还挺大，每次job都需要传递这么大一个文件，也挺浪费的。

提供两种打包方式，一种是直接jar运行的，一种是所有的jar压缩包tar.gz方式。可以结合distributecache减少每次执行程序需要传递给nodemanager的数据量，以及结合mapreduce运行时配置参数可以进行远程调试。

```
调试appmanager
-Dyarn.app.mapreduce.am.command-opts="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=18090" 
调试map
-Dmapreduce.map.java.opts
调试reduce
-Dmapreduce.reduce.java.opts
```

### 小结

通过以上3中方式基本上能处理工作终于到的大部分问题了。大部分的功能使用mrunit测试就可以了，还可以单独的测试map，或者reduce挺不错的。

### 附录：maven打包

```
	<profile>
		<id>jar</id>
		<build>
			<plugins>
				<plugin>
					<groupId>org.apache.maven.plugins</groupId>
					<artifactId>maven-assembly-plugin</artifactId>
					<executions>
						<execution>
							<id>make-assembly</id>
							<phase>package</phase>
							<goals>
								<goal>single</goal>
							</goals>
						</execution>
					</executions>
					<configuration>
						<descriptorRefs>
							<descriptorRef>
								jar-with-dependencies
							</descriptorRef>
						</descriptorRefs>
					</configuration>
				</plugin>

			</plugins>
		</build>
	</profile>

	<profile>
		<id>tar</id>
		<build>
			<plugins>
				<plugin>
					<groupId>org.apache.maven.plugins</groupId>
					<artifactId>maven-assembly-plugin</artifactId>
					<executions>
						<execution>
							<id>make-assembly</id>
							<phase>package</phase>
							<goals>
								<goal>single</goal>
							</goals>
						</execution>
					</executions>
					<configuration>
						<appendAssemblyId>true</appendAssemblyId>
						<descriptors>
							<descriptor>${basedir}/../assemblies/application.xml</descriptor>
						</descriptors>
					</configuration>
				</plugin>
			</plugins>
		</build>
	</profile>
```

打包成tar.gz的描述文件：

```
	<assembly>
		<id>dist-${env}</id>
		<formats>
			<format>tar.gz</format>
		</formats>
		<includeBaseDirectory>true</includeBaseDirectory>
		<fileSets>
			<fileSet>
				<directory>${basedir}/src/main/scripts</directory>
				<outputDirectory>/bin</outputDirectory>
				<includes>
					<include>*.sh</include>
				</includes>
				<fileMode>0755</fileMode>
				<lineEnding>unix</lineEnding>
			</fileSet>
			<fileSet>
				<directory>${basedir}/target/classes</directory>
				<outputDirectory>/conf</outputDirectory>
				<includes>
					<include>*.xml</include>
					<include>*.properties</include>
				</includes>
			</fileSet>
			<fileSet>
				<directory>${basedir}/target</directory>
				<outputDirectory>/lib/core</outputDirectory>
				<includes>
					<include>${project.artifactId}-${project.version}.jar
					</include>
				</includes>
			</fileSet>
		</fileSets>
		<dependencySets>
			<dependencySet>
				<useProjectArtifact>false</useProjectArtifact>
				<outputDirectory>/lib/common</outputDirectory>
				<scope>runtime</scope>
			</dependencySet>
		</dependencySets>
	</assembly>
```

运行整个程序的shell脚本

```
#!/bin/sh

bin=`which $0`
bin=`dirname ${bin}`
bin=`cd "$bin"; pwd`

export ANAYSER_HOME=`dirname "$bin"`

export ANAYSER_LOG_DIR=$ANAYSER_HOME/logs

export ANAYSER_OPTS="-Dproc_dta_analyser -server -Xms1024M -Xmx2048M -Danalyser.log.dir=${ANAYSER_LOG_DIR}"

export HADOOP_HOME=${HADOOP_HOME:-/home/hadoop/hadoop-2.2.0}
export ANAYSER_CLASSPATH=$ANAYSER_HOME/conf
export ANAYSER_CLASSPATH=$ANAYSER_CLASSPATH:$HADOOP_HOME/etc/hadoop

for f in $ANAYSER_HOME/lib/core/*.jar ; do
  export ANAYSER_CLASSPATH+=:$f
done

for f in $ANAYSER_HOME/lib/common/*.jar ; do
  export ANAYSER_CLASSPATH+=:$f
done

if [ ! -d $ANAYSER_LOG_DIR ] ; then
  mkdir -p $ANAYSER_LOG_DIR
fi

[ -w "$ANAYSER_PID_DIR" ] ||  mkdir -p "$ANAYSER_PID_DIR"

nohup ${JAVA_HOME}/bin/java $ANAYSER_OPTS -cp $ANAYSER_CLASSPATH com.analyser.AnalyserStarter >$ANAYSER_LOG_DIR/stdout 2>$ANAYSER_LOG_DIR/stderr &

```