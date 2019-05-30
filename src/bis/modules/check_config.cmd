@Echo Off
rem {Copyright}
rem {License}
rem Сценарий контроля исходных параметров и конфигурации пакета WAMP
rem Параметры:
rem	утилита изменения цвета вывода	: %1 (используется chcolor)
rem	конфигурационный файл пакета	: %2
rem	каталог установки пакета	: %3
rem	каталог логов			: %4
rem	каталог дистрибутивов		: %5
rem	каталог утилит			: %6 
rem	каталог вспомогательных модулей	: %7

setlocal EnableExtensions EnableDelayedExpansion

1>nul chcp 1251

rem Разбор параметров запуска
:start_parse
set p_param=%~1
set p_key=%p_param:~0,3%
set p_value=%p_param:~4%
set p_value=%p_value:"=%

if [%p_param%] == [] goto end_parse

if /i "%p_key%" EQU "-cc" set chcolor=%p_value%
if /i "%p_key%" EQU "-cf" set cfg_file=%p_value%
if /i "%p_key%" EQU "-sd" set setup_dir=%p_value%
if /i "%p_key%" EQU "-ld" set log_dir=%p_value%
if /i "%p_key%" EQU "-dd" set distrib_dir=%p_value%
if /i "%p_key%" EQU "-ud" set utils_dir=%p_value%
if /i "%p_key%" EQU "-md" set modules_dir=%p_value%

shift
goto start_parse

:end_parse

echo.
"%chcolor%" 08 & echo Victory BIS: Check Parameters {Current_Version}. {Copyright} {Current_Date}
echo.
"%chcolor%" 0F & echo | set /p dummyName=Контроль исходных параметров и конфигурации...

rem echo 1%chcolor% 2%cfg_file% 3%setup_dir% 4%log_dir% 5%distrib_dir% 6%utils_dir% 7%installer% !
rem Каталог конфигурационных файлов
for /f %%i in ("%cfg_file%") do Set cfg_dir=%%~dpi

rem Контроль обязательных значений параметров
if "%setup_dir%" EQU "" set ERR=2
if "%cfg_file%" EQU "" set ERR=3
if "%log_dir%" EQU "" set ERR=1

if NOT "%ERR%" EQU "" goto err_exec

rem Контроль наличия каталогов и файлов
:check_dirs
if NOT EXIST "%distrib_dir%" goto err_4
if NOT EXIST "%cfg_file%" goto err_5
if NOT EXIST "%log_dir%" goto err_9

if not "%distrib_dir%" EQU "" if NOT EXIST "%distrib_dir%" goto err_4

rem Контроль данных конфигурационного файла пакета
for /F "usebackq eol=; skip=1 tokens=1-4,5 delims=	" %%i in ("%cfg_file%") do if /i not "%%m" EQU "NONE" if NOT EXIST "%%m.cmd" call :err_setup_file %%m
for /F "usebackq eol=; skip=1 tokens=1-5,6 delims=	" %%i in ("%cfg_file%") do if /i not "%%n" EQU "NONE" if NOT EXIST "%%n.cmd" call :err_setup_cfg_file %%n
for /F "usebackq eol=; skip=1 tokens=1-6,7 delims=	" %%i in ("%cfg_file%") do if /i not "%%o" EQU "NONE" if NOT EXIST %%o call :err_config_file %%o
rem for /F "usebackq eol=; skip=1 tokens=1-7,8" %%i in ("%cfg_file%") do if /i not "%%p" EQU "NONE" if NOT EXIST "%%p.cmd" call :err_uninst_file %%p

rem Контроль использования прокси-сервера
rem Получаем параметры соединения с прокси-сервером
if exist "%cfg_dir%\download.ini" (
	for /F "usebackq eol=; skip=1 tokens=1,2" %%i in ("%cfg_dir%\download.ini") do (
		if "%%i" EQU "proxy_host" Set proxy_host=%%j
		if "%%i" EQU "proxy_login" Set proxy_login=%%j
		if "%%i" EQU "proxy_password" Set proxy_password=%%j
	)
	rem определяем протокол прокси-сервера
	if not "!proxy_host!" EQU "" (
		set check_protocol=!proxy_host:https://=!
		if /i not "!check_protocol!" EQU "!proxy_host!" (
			set proxy_protocol=https
		) else (
			set check_protocol=!proxy_host:http://=!
			if /i not "!check_protocol!" EQU "!proxy_host!" (
				set proxy_protocol=http
			) else (
				set proxy_protocol=http
			)
		)
		rem формируем информацию о заданном прокси-сервере
		if not "!proxy_login!" EQU "" (
			set proxy_info=!proxy_protocol!://!proxy_login!:!proxy_password!@!check_protocol!
		) else (
			set proxy_info=!proxy_protocol!://!check_protocol!
		)
	)
)
   
if "%HTTP_PROXY%" == "" (
	rem Так как переменная окружения будет доступна только после перезагрузки ОС, то проверяем реестр
	FOR /F "usebackq tokens=*" %%A IN (`%modules_dir%registry.cmd -md:"%modules_dir%" -oc:GET -vn:HTTP_PROXY 2^>nul`) DO set HTTP_PROXY=%%A
	if "!HTTP_PROXY!" == "" (
		start "Проверка использования прокси-сервера" /D "%utils_dir%" /WAIT "%utils_dir%\curl.exe" -O http://isc.sans.org/infocon.txt

		rem Если возникла ошибка соединения с хостом
		if ERRORLEVEL 1 (
			if "%proxy_host%" EQU "" goto err_setup_proxy
			call %modules_dir%registry.cmd -md:"%modules_dir%" -oc:SET -vn:HTTP_PROXY -vv:%proxy_info% 
		)
	)
) else (
	if "%proxy_host%" EQU "" goto err_setup_proxy
	if /i not "%HTTP_PROXY%" == "%proxy_info%" (
		call %modules_dir%registry.cmd -md:"%modules_dir%" -oc:SET -vn:HTTP_PROXY -vv:%proxy_info% 
	)
)

if not "%HTTP_PROXY%" EQU "" echo. & "%chcolor%" 08 & echo | set /p "dummyName=Соединение через прокси-сервер: " & "%chcolor%" 0F & echo %HTTP_PROXY%

if NOT "%ERR%" EQU "" exit /b %ERR%

"%chcolor%" 0A & echo Ok
endlocal & exit /b 0

:err_exec
goto err_%ERR%

:err_1
"%chcolor%" 0C & echo ERR %ERR%: Должен быть задан каталог логов пакета^!
endlocal & exit /b %ERR%

:err_2
"%chcolor%" 0C & echo ERR %ERR%: Должен быть задан каталог установки пакета^!
endlocal & exit /b %ERR%

:err_3
"%chcolor%" 0C & echo ERR %ERR%: Должен быть задан конфигурационный файл^!
endlocal & exit /b %ERR%

:err_4
"%chcolor%" 0C & echo ERR 4: Не найден каталог дистрибутивов пакета: %distrib_dir%
Choice /T 10 /D N /M "Создать каталог %distrib_dir%"

if "%Errorlevel%" EQU "2" goto exit_err4

1>nul MD "%distrib_dir%"
goto check_dirs

:exit_err4
endlocal & exit /b 4

:err_5
"%chcolor%" 0C & echo ERR 5: Не найден конфигурационный файл пакета (%cfg_file%)^!
endlocal & exit /b 5

:err_setup_file
set ERR=6
"%chcolor%" 0C & echo ERR %ERR%: Отсутствует установочный командный файл: %1
endlocal & exit /b %ERR%

:err_config_file
set ERR=7
"%chcolor%" 0C & echo ERR %ERR%: Отсутствует конфигурационный файл: %1
endlocal & exit /b %ERR%

:err_setup_cfg_file
set ERR=8
"%chcolor%" 0C & echo ERR %ERR%: Отсутствует файл настройки приложения: %1
endlocal & exit /b %ERR%

:err_uninst_file
set ERR=10
"%chcolor%" 0C & echo ERR %ERR%: Отсутствует деинсталляционный файл: %1
endlocal & exit /b %ERR%

:err_9
"%chcolor%" 0C & echo ERR 9: Не найден каталог логов пакета: %log_dir%
Choice /T 10 /D N /M "Создать каталог %log_dir%"

if "%Errorlevel%" EQU "2" goto exit_err9

1>nul MD "%log_dir%"
goto check_dirs

:exit_err9
endlocal & exit /b 9

:err_setup_proxy
"%chcolor%" 0C & echo ERR 11: Не найдены настройки прокси-сервера^! Проверьте, пожалуйста, конфигурационный файл download.ini
endlocal & exit /b 11

rem ---------------- EOF check_config.cmd ----------------