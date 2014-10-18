 cp -r public/* _deploy/

 (cd _deploy/ && git add -A && git commit -m "`date +%y-%m-%d`" && git push )
