@Echo Off
rem {Copyright}
rem {License}
rem Сценарий чтения и записи параметров файлов инициализации

1>nul chcp 1251

setlocal EnableExtensions EnableDelayedExpansion

rem Разбор параметров запуска
:start_parse
set p_param=%~1
set p_key=%p_param:~0,3%
set p_value=%p_param:~4%
set p_value=%p_value:"=%

if [%p_param%] EQU [] goto end_parse

if /i "%p_key%" EQU "-if" set ini_file=%p_value%
if /i "%p_key%" EQU "-ct" set category=%p_value%
if /i "%p_key%" EQU "-pn" set param_name=%p_value%
if /i "%p_key%" EQU "-op" set operation=%p_value%
shift
goto start_parse

:end_parse

rem Предварительный контроль параметров
if not exist "%ini_file%" goto ini_file_notfound
if not defined "%param_name%" goto exec_format
if not defined "%operation%" set operation=READ

for /F "usebackq eol=; tokens=1,2 delims==" %%i in ("%ini_file%") do (
	set par_value=%%j

	rem Если чтение
	if "%operation%" EQU "READ" (
		if /i "%param_name%" EQU "%%i" echo %%j	
	) else if "%operation%" EQU "WRITE" (
	rem Если запись
		
	)
)

endlocal & exit /b 0

:ini_file_notfound
"%modules_dir%bis_error.cmd" -ec:006 -v1:"%cfg_file%" -md:"%modules_dir%" -cc:"%chcolor%" 
endlocal & exit /b 1

:exec_format
"%chcolor%" 0C & echo ERR -1: Каталог вспомогательных модулей %modules_dir% не найден^! 

endlocal & exit /b 1

rem ---------------- EOF ini_params.cmd ----------------