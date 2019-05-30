@Echo Off
rem {Copyright}
rem {License}
rem Сценарий изменения хостов приложения автономной справки OHW в Adf-библиотеках проектов ViewController
rem Параметры:
rem	каталог архивов	Adf-библиотек (jar)	: %1
rem	временный каталог (temp)		: %2
rem	вычислительная среда (env)		: %4 (dev/test/prod)

setlocal EnableExtensions EnableDelayedExpansion
cls
1>nul chcp 1251

rem Разбор параметров запуска
rem Назначаем переменные и далее, по возможности, пользуемся только ими
:start_parse
set p_param=%~1
set p_key=%p_param:~0,3%
set p_value=%p_param:~4%

if "%p_param%" EQU "" goto end_parse

if "%p_key%" EQU "-ld" set adflib_dir=%p_value%
if "%p_key%" EQU "-td" set temp_dir=%p_value%
if "%p_key%" EQU "-en" set environment=%p_value%

shift
goto start_parse

:end_parse

chgcolor 08 & echo Victory ADF: Replace OHW baseURI {Current_Version}. {Copyright} {Current_Date}

if "%adflib_dir%" EQU "" call :exec_format %~nx0 & endlocal & exit /b 1
if "%temp_dir%" EQU "" call :exec_format %~nx0 & endlocal & exit /b 1
if "%environment%" EQU "" call :exec_format %~nx0 & endlocal & exit /b 1

rem Значения по умолчанию
rem Хост OHW при разработке с использованием интегрированного WebLogic
set OHW_base_URI_DEF=localhost:7101
set OHW_base_URI_DEV=sak-testwls01:7001
set OHW_base_URI_TEST=sak-testwls02:7001
set OHW_base_URI_PROD=sak-weblogic01:7001

rem Определяем хост 
if "%environment%" EQU "dev" (
	set new_OHW_base_URI=%OHW_base_URI_DEV%
) else if "%environment%" EQU "test" (
	set new_OHW_base_URI=%OHW_base_URI_TEST%
) else if "%environment%" EQU "prod" (
	set new_OHW_base_URI=%OHW_base_URI_PROD%
)

rem и абсолютные пути к каталогам
for /f %%i in ("%adflib_dir%") do Set adflib_dir=%%~dpni
for /f %%i in ("%temp_dir%") do Set temp_dir=%%~dpni

rem временные каталоги:
rem Adf-библиотек
set tmp_adflib_dir=%temp_dir%\adflib
rem файла манифеста (необходим для перепаковки jar)
set tmp_manifest_dir=%temp_dir%\adflib\manifest

rem Утилиты:
set jar=jar.exe
set svn="C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"

rem файл времени последней проверки каталога Adf-библиотек
set last_time_check_file=%temp_dir%\%environment%_last_time_check.tmp

echo.
chgcolor 08 & echo | set /p "dummyName=Окружение: " & chgcolor 0F & echo %environment%
chgcolor 08 & echo | set /p "dummyName=Каталог Adf-библиотек: " & chgcolor 0F & echo %adflib_dir%
chgcolor 08 & echo | set /p "dummyName=Временный каталог: " & chgcolor 0F & echo %temp_dir%
chgcolor 08 & echo | set /p "dummyName=Хост по умолчанию: " & chgcolor 0F & echo %OHW_base_URI_DEF%
chgcolor 08 & echo | set /p "dummyName=Хост окружения: " & chgcolor 0F & echo %new_OHW_base_URI%
chgcolor 08 & echo | set /p "dummyName=Файл последней метки времени: " & chgcolor 0F & echo %last_time_check_file%
echo.

rem создание временного каталога файла манифеста
if not exist "%tmp_manifest_dir%" 1>nul MD "%tmp_manifest_dir%"

rem получаем последнюю метку времени
if exist "%last_time_check_file%" (
	for /F "usebackq tokens=* delims=," %%n in ("%last_time_check_file%") do set last_time=%%n
	call :date_to_int last_int_time "!last_time!"
) else (
	set last_time=в первый раз
	set last_int_time=0
)

chgcolor 08 & echo | set /p "dummyName=Последняя замена хоста выполнена: " & chgcolor 0F & echo %last_time%

rem обновляем заданный каталог Adf-библиотек
echo.
chgcolor 0F & echo | set /p "dummyName=SVN: Обновление каталога Adf-библиотек... "
if exist %svn% (
	pushd %adflib_dir%
	%svn% /command:update /path:"%adflib_dir%\*" /closeonend:1
	popd
	chgcolor 0A & echo Ok
) else (
	chgcolor 0C & echo error
	chgcolor 0C & echo SVN: Каталог Adf-библиотек не обновлён - не найден SVN-клиент. Возможно, Вам придётся выполнить обновление самостоятельно.
)

rem цикл по архивам проектов ViewController в заданном каталоге Adf-библиотек вычислительной среды (dev/test/prod)
echo.
chgcolor 08 & echo | set /p "dummyName=Adf-библиотеки проектов ViewController (" & chgcolor 0F & echo | set /p "dummyName=%adflib_dir%" & chgcolor 08 & echo )
chgcolor 08 & echo -----------------------------------------------------------
FOR /f "tokens=1,2" %%a IN ('2^>nul FORFILES /p %adflib_dir% /m "*-View.jar" /C "cmd /c echo @file @fdate_@ftime"') DO (
	set adflib_file=%%~a
	set adflib_time=%%~b
	rem по времени заменяем _ на пробел (для читабельности)
  	set adflib_time=!adflib_time:_= !
	                   
	rem получаем числовую метку времени
	call :date_to_int adflib_int_time "!adflib_time!"

	chgcolor 0F & echo | set /p "dummyName=!adflib_file!	!adflib_time! (!adflib_int_time!)... "

	rem если Adf-библиотека была изменена после последней замены хоста в архивах

	if %last_int_time% LSS !adflib_int_time! (
		
		rem создание и переход во временный каталог Adf-библиотеки
		for /f %%i in ("!adflib_file!") do Set adflib_name=%%~ni
		if not exist "%tmp_adflib_dir%\!adflib_name!" 1>nul MD "%tmp_adflib_dir%\!adflib_name!"

		pushd %tmp_adflib_dir%\!adflib_name!

		rem распаковка файла META-INF\adf-settings.xml и манифеста
		rem %zip% x %adflib_dir%\!adflib_file! -o%tmp_adflib_dir%\!adflib_name! -i@ohw_extract.txt -aoa
	
		rem распаковка архива библиотеки
		%jar% xvf %adflib_dir%\!adflib_file! 2>nul

		rem перенос файла манифеста во временный каталог
		if exist "%tmp_adflib_dir%\!adflib_name!\META-INF\MANIFEST.MF" (
			1>nul move /y %tmp_adflib_dir%\!adflib_name!\META-INF\MANIFEST.MF %tmp_manifest_dir%\MANIFEST.MF
                )
		rem замена хоста по умолчанию автономного приложения хостом согласно заданной вычислительной среде (dev/test/prod)
		%b2eincfilepath%\fnr.exe --cl --dir "%tmp_adflib_dir%\!adflib_name!\META-INF" --fileMask "*.xml" --find "%OHW_base_URI_DEF%" --replace "%new_OHW_base_URI%"
		
		rem если окружение dev или prod, то ещё меняем хост сервера разработки на промышленный и обратно
		if "%environment%" EQU "dev" (
			%b2eincfilepath%\fnr.exe --cl --dir "%tmp_adflib_dir%\!adflib_name!\META-INF" --fileMask "*.xml" --find "%OHW_base_URI_PROD%" --replace "%new_OHW_base_URI%"
		) else if "%environment%" EQU "prod" (
			%b2eincfilepath%\fnr.exe --cl --dir "%tmp_adflib_dir%\!adflib_name!\META-INF" --fileMask "*.xml" --find "%OHW_base_URI_DEV%" --replace "%new_OHW_base_URI%"
		)

		rem запаковка обратно
		rem %zip% u -tzip %adflib_dir%\!adflib_file! %tmp_adflib_dir%\!adflib_name!\* -mx0
		
		rem исправление архива Adf-библиотеки (http://grep.codeconsult.ch/2011/11/15/manifest-mf-must-be-the-first-resource-in-a-jar-file-heres-how-to-fix-broken-jars/)
		if exist "%tmp_manifest_dir%\MANIFEST.MF" (
			%jar% cvf0m %adflib_dir%\!adflib_file! %tmp_manifest_dir%\MANIFEST.MF . 2>nul
		) else (
			%jar% cvf0M %adflib_dir%\!adflib_file! . 2>nul
		)

		rem выходим из временного каталога Adf-библиотеки и удаляем его, а так же файл манифеста
		popd
		1>nul RD /S /Q "%tmp_adflib_dir%\!adflib_name!"
		1,2>nul del /Q "%tmp_manifest_dir%\MANIFEST.MF"
		chgcolor 0A & echo Ok	
	) else (
		chgcolor 0A & echo pass	
	)
)
chgcolor 08 & echo -----------------------------------------------------------

rem фиксируем время выполнения замены хоста по заданному окружению
type nul > "%last_time_check_file%"
echo %date% %time%>>"%last_time_check_file%"

rem фиксируем изменения в каталоге Adf-библиотек
echo.
chgcolor 0F & echo | set /p "dummyName=SVN: Фиксация изменений в каталоге Adf-библиотек... "

if not exist %svn% goto svn_client_notfound

rem pushd %adflib_dir%
start "SVN: Фиксация изменений в каталоге Adf-библиотек" %svn% /command:commit /path:"%adflib_dir%\*" /logmsg:"Изменены хосты приложения автономной справки согласно окружению (%environment%)" /closeonend:1
rem popd
chgcolor 0A & echo Ok
endlocal & exit /b 0

:svn_client_notfound
chgcolor 0C & echo error
chgcolor 0C & echo SVN: Изменения архивов в каталоге Adf-библиотек (%adflib_dir%) не зафиксированы - не найден SVN-клиент. Возможно, Вам придётся выполнить фиксацию самостоятельно.
endlocal & exit /b 2

rem ==========================================================================
rem Процедура exec_format - печать формата запуска системы
rem ==========================================================================
:exec_format
echo.
chgcolor 08 & echo Формат запуска утилиты:
chgcolor 08 & echo %~nx1 [^<ключи^>...]
echo.
chgcolor 08 & echo Ключи:
chgcolor 0B & echo | set /p "dummyName=   -ld" & chgcolor 0F & echo :(обязательно) каталог архивов Adf-библиотек проектов ViewController (*-View.jar)
chgcolor 0B & echo | set /p "dummyName=   -td" & chgcolor 0F & echo :(обязательно) временный каталог
chgcolor 0B & echo | set /p "dummyName=   -en" & chgcolor 0F & echo :(обязательно) окружение [dev/test/prod]
exit /b 0

rem http://www.cyberforum.ru/cmd-bat/thread613576.html
:date_to_int 
set tmp.result=%~2

rem контроль значений часа и минут
set hours=%tmp.result:~11,2%
set minutes=%tmp.result:~14,2%
if "%tmp.result:~11,1%" EQU " " set hours=0%tmp.result:~12,1%
rem если был сдвиг из-за часов на 1 символ влево
if "%tmp.result:~12,1%" EQU ":" (
	set hours=0%tmp.result:~11,1%
	set minutes=%tmp.result:~13,2%
)

set /a %1=%tmp.result:~8,2%%tmp.result:~3,2%%tmp.result:~0,2%%hours%%minutes%
exit /b 0

rem ---------------- EOF owh.cmd ----------------