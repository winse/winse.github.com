@echo off

rem npp-windows redirect...
rem "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Local State" /protocol_handler

rem %~0�� ȡ�ļ�������+��չ����
rem %~f0��ȡȫ·��
rem %~d0��ȡ��������
rem %~p0��ֻȡ·����������������
rem %~n0��ֻȡ�ļ���
rem %~x0��ֻȡ�ļ���չ��
rem %~s0��ȡ��дȫ·����
rem %~a0��ȡ�ļ�����
rem %~t0��ȡ�ļ�����ʱ��
rem %~z0��ȡ�ļ���С

echo ��ǰ�̷���%~d0
echo ��ǰ�̷���·����%~dp0
echo ��ǰ������ȫ·����%~f0
echo ��ǰ�̷���·���Ķ��ļ�����ʽ��%~sdp0
echo ��ǰCMDĬ��Ŀ¼��%cd%

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
