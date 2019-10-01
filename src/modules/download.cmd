rem {Copyright}
rem {License}
rem Сценарий загрузки дистрибутивов приложений пакета Victory BIS

rem ---------------------------------------------
rem Загружает с помощью заданной утилиты загрузки
rem файл по заданному URL'у в заданный каталог пути
rem 
rem http://proft.me/2013/08/17/spravochnik-po-komandam-wget-i-curl/
rem http://linuxfreelancer.com/modifying-user-agent-in-curl-or-wget
rem http://curl.haxx.se/docs/manual.html
rem ---------------------------------------------
:download _util _url _path
setlocal
set _util=%~1
set _url=%2
set _path=%~3

rem КОНТРОЛЬ:
rem отсутствие утилиты загрузки
if not exist "%_util%" call :echo -ri:DwnldUtilExistError -v1:"%_util%" & endlocal & exit /b 1
rem отсутствие параметров: URL'a или пути дистрибутива
if [%_url%] EQU [] call :echo -ri:DistribUrlParamError & endlocal & exit /b 1
if "%_path%" EQU "" call :echo -ri:DistribPathParamError & endlocal & exit /b 1
rem определяем имя и каталог дистрибутива
for /f %%i in ("%_path%") do (
	Set l_distrib_dir=%%~dpi
	Set l_distrib_file=%%~nxi
)
rem отсутствие каталога дистрибутива модуля
if not exist "%l_distrib_dir%" call :echo -ri:DistribDirExistError -v1:"%l_distrib_dir%" & endlocal & exit /b 1

call :echo -ri:DownloadDistribFile -v1:"%l_distrib_file%" -v2:"%l_distrib_dir%" -rc:0F -ln:false -be:1

rem Определяем использование прокси-сервера
rem Так как переменная окружения будет доступна только после перезагрузки ОС или
rem параметры подключения изменились, то проверяем реестр
call :reg -oc:%RC_GET% -vn:HTTP_PROXY
if "%reg%" NEQ "" (
	SET curl_proxy=%reg:http://=-U %
	SET curl_proxy=!curl_proxy:https://=-U !
	SET curl_proxy=!curl_proxy:@= -x !
	set wget_proxy=-e http_proxy="%reg%"
)
rem Загрузка
rem http://docs.rackspace.com/servers/api/v2/cn-gettingstarted/content/curl.html
rem http://stackoverflow.com/questions/11029551/curl-command-does-not-do-what-i-exoect-in-batch
call :get_res_val -ri:DownloadDistribFile -v1:"%l_distrib_file%" -v2:"%l_distrib_dir%"
start "%res_val%" /D "%l_distrib_dir%" /WAIT "%_util%" -A "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0" ^
						-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" ^
						-H "Accept-Encoding: gzip, deflate" ^
						-H "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3" ^
						-H "Connection: keep-alive" ^
						-H "X-ClickOnceSupport	( .NET CLR 3.5.30729; .NET4.0C)" ^
						-L !curl_proxy! -o "%l_distrib_file%" %_url%

call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0
rem проверяем размер загруженного файла
rem http://stackoverflow.com/questions/15983135/can-option-of-delims-in-for-f-be-a-string
rem	set limit_byte_size=2000

rem 	FOR /F "usebackq" %%A IN ('%l_distrib_dir%\%l_distrib_file%') DO set size=%%~zA
rem 	if !size! LSS !limit_byte_size! (
rem		del /Q "%l_distrib_dir%\%l_distrib_file%"
rem		set use_wget=true
rem	)

rem Если используется wget
rem загрузка: http://gnuwin32.sourceforge.net/packages/wget.htm
rem http://www.thegeekstuff.com/2009/09/the-ultimate-wget-download-guide-with-15-awesome-examples/#more-1885
rem http://ya.dmitrov.ru/bestsoft/_utilru_fr.htm
rem http://linux.about.com/od/commands/l/blcmdl1_wget.htm
start "%res_val%" /D "%l_distrib_dir%" /WAIT "%_util%" %wget_proxy% ^
	-c -w 15 -t 100 --retry-connrefused ^
	--user-agent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:26.0) Gecko/20100101 Firefox/26.0" ^
	-O "%l_distrib_file%" ^
	%_url%

call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0
rem ---------------- EOF download.cmd ----------------
