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
' 实现无黑框无DOS窗口隐藏批处理运行窗口
' 直接命令行而已调用，但是用npp-windows url-protocel的方式就不行了！最后转换为exe行了！！

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
' 最后那个0是指窗口参数，用法为：
' 　　0 隐藏窗口并激活另一窗口。 
' 　　1 激活并显示一个窗口。若窗口是最小化或最大化，则恢复到其原来的大小和位置。 
' 　　2 激活窗口并以最小化显示该窗口。 
' 　　3 激活窗口并以最大化显示该窗口。 
' 　　4 按窗口最近的大小和位置显示。活动窗口保持活动。 
' 　　5 以当前大小和位置激活并显示窗口。 
' 　　6 最小化指定窗口并激活按 Z 序排序的下一个顶层窗口。 
' 　　7 最小化显示窗口。活动窗口保持活动。 
' 　　8 以当前状态显示窗口。活动窗口保持活动。 
' 　　9 激活并显示窗口。若窗口是最小化或最大化，则恢复到原来的大小和位置。在还原应用程序的最小化窗口时，应指定该标志。 
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
