' ScriptCryptor Project Options Begin
' HasVersionInfo: No
' Companyname: 
' Productname: 
' Filedescription: 
' Copyrights: 
' Trademarks: 
' Originalname: 
' Comments: 
' Productversion:  0. 0. 0. 0
' Fileversion:  0. 0. 0. 0
' Internalname: 
' Appicon: 
' AdministratorManifest: No
' ScriptCryptor Project Options End
' ʵ���޺ڿ���DOS�����������������д���
' ֱ�������ж��ѵ��ã�������npp-windows url-protocel�ķ�ʽ�Ͳ����ˣ����ת��Ϊexe���ˣ���

' Set objFile = CreateObject("Scripting.FileSystemObject").GetFile("npp-windows.vbs")
' 
' Wscript.Echo "Absolute path: " & objFSO.GetAbsolutePathName(objFile)
' Wscript.Echo "Parent folder: " & objFSO.GetParentFolderName(objFile) 
' Wscript.Echo "File name: " & objFSO.GetFileName(objFile)
' Wscript.Echo "Base name: " & objFSO.GetBaseName(objFile)
' Wscript.Echo "Extension name: " & objFSO.GetExtensionName(objFile)
' 
' Set objArgs = WScript.Arguments
' For I = 0 to objArgs.Count - 1
'    WScript.Echo objArgs(I)
' Next
' 
' <http://blog.csdn.net/carl6148/article/details/7905549>
' ����Ǹ�0��ָ���ڲ������÷�Ϊ��
' ����0 ���ش��ڲ�������һ���ڡ� 
' ����1 �����ʾһ�����ڡ�����������С������󻯣���ָ�����ԭ���Ĵ�С��λ�á� 
' ����2 ����ڲ�����С����ʾ�ô��ڡ� 
' ����3 ����ڲ��������ʾ�ô��ڡ� 
' ����4 ����������Ĵ�С��λ����ʾ������ڱ��ֻ�� 
' ����5 �Ե�ǰ��С��λ�ü����ʾ���ڡ� 
' ����6 ��С��ָ�����ڲ���� Z ���������һ�����㴰�ڡ� 
' ����7 ��С����ʾ���ڡ�����ڱ��ֻ�� 
' ����8 �Ե�ǰ״̬��ʾ���ڡ�����ڱ��ֻ�� 
' ����9 �����ʾ���ڡ�����������С������󻯣���ָ���ԭ���Ĵ�С��λ�á��ڻ�ԭӦ�ó������С������ʱ��Ӧָ���ñ�־�� 
' 
' vbs to exe
' http://www.sdbeta.com/xiazai/2013/0206/13137.html

Dim CurrPath
CurrPath=WScript.Createobject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path

Dim fileRelativePath
fileRelativePath=WScript.Arguments(0)

' Dim filepath
' filepath=Mid(fileRelativePath,15)

Dim Wsh
Set Wsh = WScript.CreateObject("WScript.Shell")

Wsh.Run CurrPath + "\npp-windows.bat """ + fileRelativePath + """",0,True

Set Wsh=NoThing
WScript.quit
