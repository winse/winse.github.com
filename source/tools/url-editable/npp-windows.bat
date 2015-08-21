@echo off

rem npp-windows app...
rem http://stackoverflow.com/questions/636381/what-is-the-best-way-to-do-a-substring-in-a-batch-file

set fileRelativePath=%1
set filepath="%~dp0..\..\%fileRelativePath:~17,-1%"

start E:\local\usr\share\npp\notepad++.exe %filepath%
rem pause
exit