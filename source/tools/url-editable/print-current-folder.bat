@echo on

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

set NPP_APP=%~dp0npp-windows.bat
set NPP_ARG=%%1

pause
