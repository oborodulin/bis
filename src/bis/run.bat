@echo off
copy /y %cd%\..\modules\definitions.cmd + /a %cd%\bis.cmd + /a %cd%\..\modules\download.cmd + /a %cd%\..\modules\echo.cmd + /a %cd%\..\modules\params.cmd + /a %cd%\..\modules\registry.cmd + /a %cd%\..\modules\strings.cmd + /a %cd%\..\modules\utils.cmd %cd%\bis_.cmd /a
rem call %cd%\bis_.cmd %*
rem call %cd%\bis_.cmd -lc:ru -ul:true -ll:5 -em:dbg
call %cd%\bis_.cmd -lc:ru -ul:true -ll:4 -em:run -dd:D:\Install\bis -pn:java -mn:apache-tomcat
rem | D:\Work\Projects.cmd\bis\src\bis\utils\x86\mtee.exe %cd%\bis.txt
rem -mn:openjdk
rem -pn:ide -mn:autoit
rem -pn:java -mn:eclipse
rem -pn:cvs -mn:git
rem call %cd%\bis_.cmd -lc:ru -ul:true -ll:5 -em:run -pn:cvs
del /q %cd%\bis_.cmd
