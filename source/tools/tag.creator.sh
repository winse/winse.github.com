#! /bin/sh

## for f in `find * -type d`; do cp git/index.md $f; done

tools=`dirname "$0"`
tools=`cd "$tools"; pwd`

if [ ! -f "$tools/../tags/tags" ]
then
	echo "$tools/../tags/tags文件不存在，请确认脚本文件相对路径是否正确！！"
	exit 1;
fi

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
