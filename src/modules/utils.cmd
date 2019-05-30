rem {Copyright}
rem {License}
rem Сценарий системных утилит

rem ---------------------------------------------
rem Возвращает архитектуру процессора (x86|x64)
rem ---------------------------------------------
:get_proc_arch
setlocal
set _proc_name=%~0

rem Определяем разрядность системы (http://social.technet.microsoft.com/Forums/windowsserver/en-US/cd44d6d3-bdfa-4970-b7db-e3ee746d6213/determine-%PA_X86%-or-%PA_X64%-from-registry?forum=winserverManagement)
call :reg -oc:%RC_GET% -vn:PROCESSOR_ARCHITECTURE
if "%reg%" EQU "" call :echo -ri:ProcArchAutoDefError -rl:0FILE & exit /b 1

rem http://social.msdn.microsoft.com/Forums/en-US/5a316848-1ec3-4d01-a395-7c5b17756239/determining-current-cpu-architecture-x32-or-%PA_X64%
if "%reg%" EQU "%PA_X86%" (set l_proc_arch=%reg%) else (set l_proc_arch=%PA_X64%)
endlocal & set "%_proc_name:~5%=%l_proc_arch%"
exit /b 0

rem ---------------------------------------------
rem Возвращает локаль системы (ru|en|...)
rem ---------------------------------------------
:get_locale
setlocal
set _proc_name=%~0
FOR /F "delims==" %%A IN ('systeminfo.exe ^|  findstr ";"') do  (
	FOR /F "usebackq tokens=2-3 delims=:;" %%B in (`echo %%A`) do (
		set VERBOSE_SYSTEM_LOCALE=%%C
		REM Removing useless leading spaces ...
		FOR /F "usebackq tokens=1 delims= " %%D in (`echo %%B`) do (
			set SYSTEM_LOCALE=%%D
			goto :locale_get_success
		)
		rem set SYSTEM_LOCALE_WITH_SEMICOLON=!SYSTEM_LOCALE!;
		rem set | findstr /I locale
		REM No need to handle second line, quit after first one
	)
)
endlocal & exit /b 1

:locale_get_success
endlocal & set "%_proc_name:~5%=%SYSTEM_LOCALE%"
exit /b 0

rem ---------------------------------------------
rem Возвращает текущую дату или время в формате ISO
rem http://ss64.com/nt/syntax-getdate.html
rem ---------------------------------------------
:get_iso_date
setlocal
set _proc_name=%~0
set _date_format=%~1

if "%_date_format%" EQU "" endlocal & exit /b 1

:: Check WMIC is available
WMIC.EXE Alias /? >NUL 2>&1 || (endlocal & exit /b 1)

:: Use WMIC to retrieve date and time
FOR /F "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
	IF "%%~L"=="" goto s_done
	Set _yyyy=%%L
	Set _mm=00%%J
	Set _dd=00%%G
	Set _hour=00%%H
	SET _minute=00%%I
)
:s_done

:: Pad digits with leading zeros
Set _mm=%_mm:~-2%
Set _dd=%_dd:~-2%
Set _hour=%_hour:~-2%
Set _minute=%_minute:~-2%

:: Display the date/time in ISO 8601 format:
if "%_date_format%" EQU "%DF_DATE_TIME%" Set l_isodate=%_yyyy%-%_mm%-%_dd% %_hour%:%_minute%
if "%_date_format%" EQU "%DF_DATE_CODE%" Set l_isodate=%_yyyy%%_mm%%_dd%
if "%_date_format%" EQU "%DF_DATE%" Set l_isodate=%_yyyy%-%_mm%-%_dd%
if "%_date_format%" EQU "%DF_TIME%" Set l_isodate=%_hour%:%_minute%

rem :get_date_error
	rem Echo Ошибка формирования текущей даты. 1>&2

endlocal & set "%_proc_name:~5%=%l_isodate%"
exit /b 0

rem ---------------- EOF utils.cmd ----------------
