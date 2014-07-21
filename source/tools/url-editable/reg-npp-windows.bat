@echo off

rem npp-windows redirect...
rem "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Local State" /protocol_handler

rem %~0： 取文件名（名+扩展名）
rem %~f0：取全路径
rem %~d0：取驱动器名
rem %~p0：只取路径（不包驱动器）
rem %~n0：只取文件名
rem %~x0：只取文件扩展名
rem %~s0：取缩写全路径名
rem %~a0：取文件属性
rem %~t0：取文件创建时间
rem %~z0：取文件大小

echo 当前盘符：%~d0
echo 当前盘符和路径：%~dp0
echo 当前批处理全路径：%~f0
echo 当前盘符和路径的短文件名格式：%~sdp0
echo 当前CMD默认目录：%cd%

@echo on

set NPP_APP=%~dp0npp-windows.bat
set NPP_ARG=%%1

set "NPP_CMD=\"%NPP_APP%\" \"%NPP_ARG%\""
rem set "NPP_CMD=mshta vbscript:createobject(\"wscript.shell\").run(\"\"\"%NPP_APP%\"\" \"\"%NPP_ARG%\"\"\",1)(window.close)&&exit " 

reg add "HKEY_CLASSES_ROOT\npp-windows" /f
reg add "HKEY_CLASSES_ROOT\npp-windows" /ve /t REG_SZ /d "URL:npp-windows Protocol" /f
reg add "HKEY_CLASSES_ROOT\npp-windows" /v "URL Protocol" /t REG_SZ /d "" /f

reg add "HKEY_CLASSES_ROOT\npp-windows\DefaultIcon"  /f
reg add "HKEY_CLASSES_ROOT\npp-windows\DefaultIcon"  /ve /t REG_SZ /d "" /f

reg add "HKEY_CLASSES_ROOT\npp-windows\shell" /f
reg add "HKEY_CLASSES_ROOT\npp-windows\shell\open" /f
reg add "HKEY_CLASSES_ROOT\npp-windows\shell\open\command" /f
reg add "HKEY_CLASSES_ROOT\npp-windows\shell\open\command" /ve /t REG_SZ /d "%NPP_CMD%" /f


pause
