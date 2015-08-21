#!/bin/sh 

PRG="$0"
PRGDIR=`dirname "$PRG"`
cd $PRGDIR/..

jekyll serve --trace -w
