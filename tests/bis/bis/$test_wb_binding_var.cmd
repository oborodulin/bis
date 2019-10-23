@Echo Off
rem {Copyright}
rem {License}
rem Сценарий глобальных определений и констант

::Define a BS variable containing a backspace (0x08) character
for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
rem разделитель каталогов ОС
set DIR_SEP=\
rem разделитель файлов ОС
set PATH_SEP=;
rem уровни логгирования: 0 - сообщения в файл, 1 - сообщения на экран, 2 - ошибки, 3 - предупреждения, 4 - информация, 5 - отладка
set LL_FILE=0
set LL_CON=1
set LL_ERR=2
set LL_WRN=3
set LL_INF=4
set LL_DBG=5
rem уровень логгирования по умолчанию: ошибки
set LL_DEF=%LL_ERR%
rem логические константы
set VL_TRUE=true
set VL_FALSE=false
rem режимы выполнения системы: эмуляции, тестовый, промышленный, отладки
set EM_EML=EML
set EM_TST=TST
set EM_RUN=RUN
set EM_DBG=DBG
rem коды возврата текущего режима выполнения
set CODE_EML=0
set CODE_TST=1
set CODE_RUN=2
set CODE_DBG=3
rem задержка выбора в меню по умолчанию (сек.)
set DEF_DELAY=20
set SHORT_DELAY=10
rem признаки простого выбора пользователя в меню
set YN_CHOICE=yn
set YES=1
set NO=2
rem команды работы с реестром
set RC_GET=GET
set RC_SET=SET
set RC_ADD=ADD
set RC_DEL=DEL
rem предопределённые разделы реестра
set RH_HKLM=HKLM
set RH_HKCU=HKCU
rem направления конфертации слешей в путях к файлам
set CSD_WIN=WIN
set CSD_NIX=NIX
rem признаки конвертации регистра строки
set CM_UPPER=UPPER
set CM_LOWER=LOWER
rem форматы представления даты и времени
set DF_DATE_TIME=DATE_TIME
set DF_DATE_CODE=DATE_CODE
set DF_DATE=DATE
set DF_TIME=TIME
rem архитектуры (разрядность) процессора и ОС
set PA_X86=x86
set PA_X64=x64

rem ---------------- EOF definitions.cmd ----------------
@Echo Off
rem Тест BIS: работа со связываемыми переменными
setlocal EnableExtensions EnableDelayedExpansion

set src_script=%~1

if not exist "%src_script%" endlocal & exit /b 2
call "%~dp0set_envs.cmd"

for /f %%i in ("%src_script%") do (
	set src_dir=%%~dpi
	set src_name=%%~ni
)
pushd "%src_dir%"
rem Устанавливаем все необходимые параметры и ресурсы для работы системы, и проверяем их корректность
rem echo on
call :%src_name%_setup -lc:ru -ul:true -ll:5 -em:run -pn:%tst_pkg_name% -mn:%tst_mod1_name%
call :%src_name%_check_setup
if ERRORLEVEL 1 popd & endlocal & exit /b 2

call :packages_menu "%p_pkg_name%" "%p_pkg_choice%" g_pkg_cfg_file g_pkg_name g_pkg_descr use_log g_log_level
echo %g_pkg_cfg_file% %g_pkg_name% %g_pkg_descr% %use_log% %g_log_level%
rem echo on
call :get_pkg_dirs "%g_pkg_name%"
pause
call :modules_menu "%p_mod_name%" "%p_mod_choice%" "%g_pkg_name%" "%g_pkg_descr%" g_mod_name g_mod_ver
call :get_mod_install_dirs "%p_pkg_name%" "%g_mod_name%" "%g_mod_ver%"
echo "%p_pkg_name%" "%g_mod_name%" "%g_mod_ver%"
pause
exit

rem Контроль областей видимости переменных
call :get_var_scope %BV_BIS_DIR% scope_pkg scope_mod
if /i "%scope_pkg%" NEQ "%DEF_VAR_PKG%" set test_fail=%VL_TRUE%
if defined scope_mod set test_fail=%VL_TRUE%
if defined test_fail popd & endlocal & exit /b 10

call :get_var_scope %BV_PROG_FILES_DIR% scope_pkg scope_mod
if /i "%scope_pkg%" NEQ "%DEF_VAR_PKG%" set test_fail=%VL_TRUE%
if defined scope_mod set test_fail=%VL_TRUE%
if defined test_fail popd & endlocal & exit /b 11

call :get_var_scope %BV_PKG_NAME% scope_pkg scope_mod
if /i "%scope_pkg%" NEQ "%g_pkg_name%" set test_fail=%VL_TRUE%
if defined scope_mod set test_fail=%VL_TRUE%
if defined test_fail popd & endlocal & exit /b 11
pause
exit

call :set_var_value %BV_BIS_DIR% "%CUR_DIR%"
call :set_var_value %BV_WIN_DIR% "%windir%"
call :set_var_value %BV_PROG_FILES_DIR% "%programfiles%"

call :set_var_value %BV_PKG_NAME% "%g_pkg_name%"
call :set_var_value %BV_PKG_SETUP_DIR% "!pkgs[%_pkg_name%]#SetupDir!"

call :set_var_value %BV_MOD_VERSION% "%g_mod_ver%"
call :set_var_value %BV_MOD_DISTR_DIR% "!mods[%_mod_name%]#DistribDir!"
call :set_var_value %BV_MOD_SETUP_DIR% "!mods[%_mod_name%]#SetupDir!"



popd
endlocal & exit /b 0
rem ---------------- EOF test_wb_binding_var.cmd ----------------
@Echo Off
rem {Copyright}
rem {License}
rem Сценарий загрузки дистрибутивов и установки заданнго пакета модулей Victory BIS
rem Параметры: запуск сценария без параметров

setlocal EnableExtensions EnableDelayedExpansion

if /i "%EXEC_MODE%" NEQ "%EM_TST%" cls

:run_tests
rem наименование сценария и его заголовок
set g_script_name=%~nx0
set g_script_name=%g_script_name:cmd-win1251.cmd=exe%
set g_script_header=Victory BIS for Windows 7/10 {Current_Version}. {Copyright} {Current_Date}

rem Устанавливаем все необходимые параметры и ресурсы для работы системы, и проверяем их корректность
call :bis_setup %*
call :bis_check_setup
if ERRORLEVEL 1 endlocal & exit /b 1

rem если уровень логгирования не задан или меньше или равен LL_INF, то продолжаем установку
if not defined p_log_level goto pkg_menu_loop
if %p_log_level% LEQ %LL_INF% goto pkg_menu_loop
rem иначе (а так же для уровня логгирования LL_DBG) - запрашиваем разрешение на продолжение установки
call :choice_process "" ProcessingSetup
if ERRORLEVEL %NO% call :echo -ri:SetupAbort & endlocal & exit /b 0

rem Цикл отображения меню выбора конфигураций пакетов
:pkg_menu_loop
call :packages_menu "%p_pkg_name%" "%p_pkg_choice%" g_pkg_cfg_file g_pkg_name g_pkg_descr use_log g_log_level
rem "Выход"
if ERRORLEVEL 1 endlocal & exit /b 0

rem сбрасываем заданный выбор и позволяем системе завершиться самостоятельно
set p_pkg_choice=
set p_pkg_name=

rem если параметров логгирования нет у пакета, то устанавливаем системные
if not defined use_log set use_log=%p_use_log%
if not defined g_log_level set g_log_level=%p_log_level%

call :echo -rv:"%g_pkg_cfg_file% %g_pkg_name% %g_pkg_descr% %use_log% %g_log_level%" -rl:5FINE

rem определяем общий каталог установки
call :get_pkg_dirs "%g_pkg_name%"

rem при необходимости, если задано логгирование в пакете, переопределяем общий лог-файл на пакетный
if /i "%use_log%" EQU "%VL_TRUE%" (
	if not exist "!pkgs[%g_pkg_name%]#LogDir!" 1>nul MD "!pkgs[%g_pkg_name%]#LogDir!"
	set g_log_file=!pkgs[%g_pkg_name%]#LogDir!%DIR_SEP%%g_pkg_name%.log
)
rem Цикл отображения меню выбора модулей
:mod_menu_loop
 
call :modules_menu "%p_mod_name%" "%p_mod_choice%" "%g_pkg_name%" "%g_pkg_descr%" g_mod_name g_mod_ver
rem "Установить все модули"
if ERRORLEVEL 3 call :echo -ri:FuncNotImpl & endlocal & exit /b 0
rem "Возврат"
if ERRORLEVEL 2 goto pkg_menu_loop
rem "Выход"
if ERRORLEVEL 1 endlocal & exit /b 0

call :echo -rv:"%g_mod_name% %g_mod_ver%" -rl:5FINE

call :echo -ri:CfgFile -v1:"%g_pkg_cfg_file%"
call :echo -ri:SetupDir -v1:"!pkgs[%g_pkg_name%]#SetupDir!"

call :execute_module "%p_exec_choice%" "%g_pkg_name%" "%g_mod_name%" "%g_mod_ver%"
if ERRORLEVEL 1 (
	set l_em_res=%ERRORLEVEL%
	echo from execute_module return code: "!l_em_res!"
	pause
	exit /b !l_em_res!
)
call :print_var_values
pause
rem сбрасываем заданный выбор и позволяем системе завершиться самостоятельно
set p_mod_choice=
set p_exec_choice=
set p_mod_name=

goto mod_menu_loop

endlocal & exit /b 0

rem =======================================================================================
rem Так как в условных конструкциях невозможно получить корректный Errorlevel от Choice, то 
rem для взаимодействия с пользователем используются подпрограммы

rem ---------------------------------------------
rem Отображение меню конфигураций пакетов
rem Возвращает: g_pkg_cfg_file g_pkg_name g_pkg_descr use_log g_log_level
rem ---------------------------------------------
:packages_menu _def_pkg_name _pkg_choice
if /i "%EXEC_MODE%" EQU "%EM_RUN%" CLS
set _def_pkg_name=%~1
set _pkg_choice=%~2
set l_delay=%DEF_DELAY%
set l_choice=
if "%_def_pkg_name%" EQU "" (
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -be:1
	call :echo -rf:"%menus_file%" -ri:ChoicePackage -v1:%l_delay% -rc:0E
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -ae:1
)
rem если данные по пакетам уже получены
if defined g_pkg_cnt (
rem выводим их
	for /l %%p in (1,1,%g_pkg_cnt%) do (
		call :echo -rv:"%%p - !g_pkg[%%p]#Name!	!g_pkg[%%p]#Descr!" -rc:0F -cp:65001 -rs:8
		set l_choice=!l_choice!%%p
	)
 	set /a "x=%g_pkg_cnt%+1"
) else (
	pushd "%bis_config_dir%"
	1>nul chcp 65001
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathPkgs
	set "x=1" 
	rem получаем имена, описания и уровни логгирования всех пакетов из файлов конфигураций в конфигурационном каталоге
	for /F %%i in ('dir *.xml /b /o:n /a-d') do (
		set l_pkg_cfg_file=%%i
		for /F "tokens=1-4 delims=	()" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	(" -v "./description" -o ")	" -v "./useLog" -o "	" -v "./logLevel" -n "%bis_config_dir%%DIR_SEP%!l_pkg_cfg_file!"') do (
			set l_pkg_name=%%~a
			set l_pkg_descr=%%~b
			call :trim !l_pkg_name! l_trim_pkg_name

			if "%_def_pkg_name%" EQU "" call :echo -rv:"!x! - !l_pkg_name!	!l_pkg_descr!" -rc:0F -cp:65001 -rs:8
			set g_pkg[!x!]#File=!l_pkg_cfg_file!
			set g_pkg[!x!]#Name=!l_pkg_name!
			set g_pkg[!x!]#Descr=!l_pkg_descr!
			set g_pkg[!x!]#UseLog=%%~c
			set g_pkg[!x!]#LogLevel=%%~d
			if /i "%_def_pkg_name%" EQU "!l_trim_pkg_name!" set _pkg_choice=!x!
		)
		set l_choice=!l_choice!!x!
	 	set /a "x+=1"
	)
	popd
	set /a "g_pkg_cnt=!x!-1"
)
set l_choice=!l_choice!!x!
1>nul chcp 1251
if "%_def_pkg_name%" EQU "" call :echo -rf:"%menus_file%" -ri:ActionDefExit -v1:%x% -rc:0D -rs:8 -be:1 -ae:1

rem если определён выбор номера пакета по умолчанию
if "%_pkg_choice%" NEQ "" set "pkg_num=%_pkg_choice%" & goto package_def

call :get_res_val -rf:"%menus_file%" -ri:EnterPkgChoice -v1:%x%
call :choice_process "" "" %l_delay% %x% "%res_val%" "%l_choice%"
set pkg_num=%ERRORLEVEL%

if %pkg_num% GEQ %x% call :echo -ri:PkgMenuAbort & exit /b 1

:package_def
for /f "usebackq delims==# tokens=1-3" %%j in (`set g_pkg[%pkg_num%]`) do (
	rem echo %%j %%k %%l
	set l_pkg_cur#%%k=%%l
) 
call :trim %l_pkg_cur#Name% l_pkg_name
call :set_var_value %BV_PKG_NAME% "%l_pkg_name%"

set %3=%bis_config_dir%%DIR_SEP%%l_pkg_cur#File%
set %4=%l_pkg_name%
set %5=%l_pkg_cur#Descr%
set %6=%l_pkg_cur#UseLog%
set %7=%l_pkg_cur#LogLevel%
exit /b 0

rem ---------------------------------------------
rem Отображение меню модулей заданного пакета
rem Возвращает: g_mod_name g_mod_ver
rem (устанавливает: 	mods[%_mod_name%]#SetupDir
rem 					mods[%_mod_name%]#BinDirCnt
rem 					mods[%_mod_name%]#BinDirs[i]
rem 					mods[%_mod_name%]#HomeEnv
rem 					mods[%_mod_name%]#HomeDir
rem						mods[%_mod_name%]#Installed)
rem ---------------------------------------------
:modules_menu _def_mod_name _mod_choice _pkg_name _pkg_descr
set _def_mod_name=%~1
set _mod_choice=%~2
set _pkg_name=%~3
set _pkg_descr=%~4
if /i "%EXEC_MODE%" EQU "%EM_RUN%" CLS
set l_delay=%DEF_DELAY%
set l_choice=

if "%_def_mod_name%" EQU "" (
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -be:1
	call :echo -rf:"%menus_file%" -ri:ChoiceModule -v1:%l_delay% -rc:0E
	call :echo -rv:"%_pkg_name% [%_pkg_descr%]" -rc:0E
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -ae:1
)
pushd "%bis_config_dir%"
1>nul chcp 65001
set "x=1"
rem получаем имена и версии всех модулей в заданном пакете
call :get_res_val -rf:"%xpaths_file%" -ri:XPathMods
for /F "tokens=1-3 delims=	" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	" -v "./version" -o "	" -v "./description" -n "%g_pkg_cfg_file%"') do (
	set l_mod_name=%%a
	set l_mod_name=!l_mod_name:~0,10!
	call :trim !l_mod_name! l_trim_mod_name
	set l_mod_ver=%%b
	set l_mod_ver=!l_mod_ver:~0,12!
	set l_mod_descr=%%c

	if "%_def_mod_name%" EQU "" call :echo -rv:"%BS%         !x! - !l_mod_name! v.!l_mod_ver! " -rc:0F -cp:65001 -ln:%VL_FALSE%
	rem получаем каталог установки модуля, его каталог бинарных файлов и домашний каталог
	call :get_mod_install_dirs "%_pkg_name%" "!l_mod_name!" "!l_mod_ver!"
	rem определяем установлен ли уже модуль
	call :is_mod_installed "!l_mod_name!" "!l_mod_ver!"
	rem если модуль установлен, переходим к выбору вариантов работы с модулем
	if "%_def_mod_name%" EQU "" (
		if ERRORLEVEL 1 call :echo -rv:"[+]" -rc:0D -ln:%VL_FALSE%
		call :echo -rv:"!l_mod_descr!" -rc:0F -cp:65001 -rs:8
	)
	set g_mod[!x!]#Name=!l_mod_name!
	set g_mod[!x!]#Ver=!l_mod_ver!
	if /i "%_def_mod_name%" EQU "!l_trim_mod_name!" set _mod_choice=!x!
	set l_choice=!l_choice!!x!
 	set /a "x+=1"
)
popd
set all_num=%x%
set l_choice=!l_choice!!x!
1>nul chcp 1251
if "%_def_mod_name%" EQU "" call :echo -rf:"%menus_file%" -ri:SetupAllModules -v1:%all_num% -rc:0D -rs:9 -be:1

set /a "x+=1"
set ret_pkg=%x%
set l_choice=!l_choice!!x!
if "%_def_mod_name%" EQU "" call :echo -rf:"%menus_file%" -ri:ActionReturnToPkgMenu -v1:%ret_pkg% -rc:0D -rs:9

set /a "x+=1"
set l_choice=!l_choice!!x!
if "%_def_mod_name%" EQU "" call :echo -rf:"%menus_file%" -ri:ActionExit -v1:%x% -rc:0D -rs:9 -ae:1

rem если определён выбор номера модуля по умолчанию
if "%_mod_choice%" NEQ "" set "mod_num=%_mod_choice%" & goto module_def

call :get_res_val -rf:"%menus_file%" -ri:EnterModChoice -v1:%x%
call :choice_process "" "" %l_delay% %ret_pkg% "%res_val%" "%l_choice%"
set mod_num=%ERRORLEVEL%

if %mod_num% GEQ %x% call :echo -ri:ModMenuAbort -v1:"%_pkg_name%" & exit /b 1
if %mod_num% GEQ %ret_pkg% exit /b 2
if %mod_num% GEQ %all_num% exit /b 3

:module_def
for /f "usebackq delims==# tokens=1-3,*" %%j in (`set g_mod[%mod_num%]`) do set l_mod_cur#%%k=%%l%%m

call :trim %l_mod_cur#Name% l_trim_mod_name
call :convert_case %CM_LOWER% "%l_trim_mod_name%" l_lw_mod_name
call :set_var_value %BV_MOD_NAME% "%l_trim_mod_name%"
call :set_var_value %BV_MOD_VERSION% "%l_mod_cur#Ver%"

set %5=%l_lw_mod_name%
set %6=%l_mod_cur#Ver%
exit /b 0

rem ---------------------------------------------
rem Определяет каталог установки пакета
rem (устанавливает: 	pkgs[%_pkg_name%]#SetupDir
rem 					pkgs[%_pkg_name%]#LogDir
rem 					pkgs[%_pkg_name%]#DistribDir
rem 					pkgs[%_pkg_name%]#BackupDataDir
rem 					pkgs[%_pkg_name%]#BackupConfigDir)
rem ---------------------------------------------
:get_pkg_dirs _pkg_name
set _pkg_name=%~1
call :get_res_val -rf:"%xpaths_file%" -ri:XPathOSParams
for /F "tokens=1-5" %%a in ('%xml_sel_% "!res_val!" -v "concat(./setupDir, substring('%EMPTY_NODE%', 1 div not(./setupDir)))" -o "	" -v "concat(./distribDir, substring('%EMPTY_NODE%', 1 div not(./distribDir)))" -o "	" -v "concat(./backupDataDir, substring('%EMPTY_NODE%', 1 div not(./backupDataDir)))" -o "	" -v "concat(./backupConfigDir, substring('%EMPTY_NODE%', 1 div not(./backupConfigDir)))" -o "	" -v "concat(./logDir, substring('%EMPTY_NODE%', 1 div not(./logDir)))" -n "%g_pkg_cfg_file%"') do (
	set pkgs[%_pkg_name%]#SetupDir=%%~a
	call :set_var_value %BV_PKG_SETUP_DIR% "!pkgs[%_pkg_name%]#SetupDir!"
	echo 2
	call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#SetupDir!" pkgs[%_pkg_name%]#SetupDir
	echo 3
	echo off
	if "%%~b" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#DistribDir=%%~b
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#DistribDir!" pkgs[%_pkg_name%]#DistribDir
	) else (
		set pkgs[%_pkg_name%]#DistribDir=%bis_distrib_dir%%DIR_SEP%%_pkg_name%
	)
	if "%%~c" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#BackupDataDir=%%~c
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#BackupDataDir!" pkgs[%_pkg_name%]#BackupDataDir
	) else (
		set pkgs[%_pkg_name%]#BackupDataDir=%bis_backup_data_dir%
	)
	if "%%~d" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#BackupConfigDir=%%~d
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#BackupConfigDir!" pkgs[%_pkg_name%]#BackupConfigDir
	) else (
		set pkgs[%_pkg_name%]#BackupConfigDir=%bis_backup_config_dir%
	)
	if "%%~e" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#LogDir=%%~e
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#LogDir!" pkgs[%_pkg_name%]#LogDir
	) else (
		set pkgs[%_pkg_name%]#LogDir=%bis_log_dir%
	)
)
call :echo -ri:PkgSetupDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#SetupDir!"
call :echo -ri:PkgLogDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#LogDir!"
call :echo -ri:PkgDistribDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#DistribDir!"
call :echo -ri:PkgBackupDataDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#BackupDataDir!"
call :echo -ri:PkgBackupConfigDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#BackupConfigDir!"
exit /b 0

rem ---------------------------------------------
rem Выполняет установку заданного модуля
rem (устанавливает: 	mods[%_mod_name%]#DistribDir)
rem ---------------------------------------------
:execute_module
set _exec_choice=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4

rem получаем каталог установки модуля, его каталог бинарных файлов и домашний каталог
call :get_mod_install_dirs "%_pkg_name%" "%_mod_name%" "%_mod_ver%"

rem определяем каталог дистрибутива модуля (должен быть определён до :execute_choice)
call :get_mod_distrib_params "%_pkg_name%" "%_mod_name%" "%_mod_ver%"

rem определяем установлен ли уже модуль
call :is_mod_installed "%_mod_name%" "%_mod_ver%"
rem если модуль установлен, переходим к выбору вариантов работы с модулем
if /i "%EXEC_MODE%" EQU "%EM_RUN%" cls
if ERRORLEVEL 1 endlocal & call :execute_choice "%_exec_choice%" "%_pkg_name%" "%_mod_name%" "%_mod_ver%" & exit /b !ERRORLEVEL!

rem выполняем все фазы модуля
call :execute_mod_phases "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
exit /b 0

rem ---------------------------------------------
rem Выполняет все фазы заданного модуля
rem ---------------------------------------------
:execute_mod_phases
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem получаем фазы выполнения
call :get_mod_phases "%_mod_name%" "%_mod_ver%"
rem разбор по явным целям в порядке следования
for /l %%n in (0,1,!mods[%_mod_name%]#PhaseCnt!) do ( 
	call :get_exec_code
	if ERRORLEVEL %CODE_RUN% (
		call :execute_phase "!mods[%_mod_name%]#Phase[%%n]@Id!" "!mods[%_mod_name%]#Phase[%%n]@Name!" "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
		if ERRORLEVEL 1 exit /b %ERRORLEVEL%
	)
) 
exit /b 0

rem ---------------------------------------------
rem Получает фазы установки заданного модуля
rem (устанавливает: 	mods[%_mod_name%]#Phase[!ps!]@Id
rem 					mods[%_mod_name%]#Phase[!ps!]@Name)
rem ---------------------------------------------
:get_mod_phases _mod_name _mod_ver
set _mod_name=%~1
set _mod_ver=%~2

if defined mods[%_mod_name%]#PhaseCnt exit /b 0
rem получаем фазы модуля
set "ps=0"
call :get_res_val -rf:"%xpaths_file%" -ri:XPathModExecs -v1:"%_mod_name%" -v2:"%_mod_ver%"
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./phase" -o "	" -v "./id" -n "%g_pkg_cfg_file%"') do (
	set l_phase=%%~a
	if "%%b" NEQ "" (
		set l_phase_id=%%~b
	) else (
		set l_phase_id=%_mod_name%-!l_phase!
	)
	set mods[%_mod_name%]#Phase[!ps!]@Id=!l_phase_id!
	set mods[%_mod_name%]#Phase[!ps!]@Name=!l_phase!
	set /a "ps+=1"
)
set /a "ps-=1"
set mods[%_mod_name%]#PhaseCnt=%ps%
exit /b 0

rem ---------------------------------------------
rem Выполняет заданную фазу
rem ---------------------------------------------
:execute_phase
setlocal
set _phase_id=%~1
set _phase=%~2
set _pkg_name=%~3
set _mod_name=%~4
set _mod_ver=%~5

call :echo -ri:ExecPhaseId -v1:"%_phase_id%" -ae:1
call :choice_process "%_phase_id%" ProcessingPhase
if ERRORLEVEL %NO% call :echo -ri:PhaseExecAbort -v1:"%_phase_id%" & endlocal & exit /b 0
if /i "%_phase%" EQU "%PH_DOWNLOAD%" call :phase_download "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
if /i "%_phase%" EQU "%PH_INSTALL%" call :phase_install "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
if /i "%_phase%" EQU "%PH_CONFIG%" call :phase_config "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem Возвращает параметры дистрибуции заданного модуля
rem (устанавливает: 	mods[%_mod_name%]#DistribDir
rem 					mods[%_mod_name%]#DistribUrl
rem 					mods[%_mod_name%]#DistribFile
rem 					mods[%_mod_name%]#DistribPath)
rem ---------------------------------------------
:get_mod_distrib_params _pkg_name _mod_name _mod_ver
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

if defined mods[%_mod_name%]#DistribPath exit /b 0
rem определяем каталог дистрибутива модуля (должен быть определён до :execute_choice)
set mods[%_mod_name%]#DistribDir=!pkgs[%_pkg_name%]#DistribDir!%DIR_SEP%%_mod_name%%DIR_SEP%%_mod_ver%
call :set_var_value %BV_MOD_DISTR_DIR% "!mods[%_mod_name%]#DistribDir!"
rem получаем URL дистрибутива и имя его файла
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseDownload -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%proc_arch%
for /F "tokens=1,2" %%a in ('%xml_sel_% "%res_val%" -v "../distribUrl" -o "	" -v "../distribFile" -n "%g_pkg_cfg_file%"') do (
	set mods[%_mod_name%]#DistribUrl=%%~a
	if "%%~b" NEQ "" (
		set mods[%_mod_name%]#DistribFile=%%~b
	) else (
		set mods[%_mod_name%]#DistribFile=%%~nxa
	)
)
rem определяем путь к дистрибутиву модуля
set mods[%_mod_name%]#DistribPath=!mods[%_mod_name%]#DistribDir!%DIR_SEP%!mods[%_mod_name%]#DistribFile!
exit /b 0

rem ====================================================================================================================
rem ФАЗЫ ВЫПОЛНЕНИЯ:
rem ====================================================================================================================

rem ---------------------------------------------
rem Загружает отсутствующие дистрибутивы пакета
rem ---------------------------------------------
:phase_download _pkg_name _mod_name _mod_ver
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

call :get_mod_distrib_params "%_pkg_name%" "%_mod_name%" "%_mod_ver%"

setlocal
call :echo -ri:ModDistribUrl -v1:%_mod_name% -v2:"!mods[%_mod_name%]#DistribUrl!"
call :echo -ri:ModDistribPath -v1:%_mod_name% -v2:"!mods[%_mod_name%]#DistribPath!"

if not exist "!mods[%_mod_name%]#DistribPath!" goto exec_download

call :echo -ri:ModDistribFound -v1:!mods[%_mod_name%]#DistribPath! -rc:0F

call :choice_process "%~0" UseExistDistrib %SHORT_DELAY%
if %choice% EQU %YES% call :echo -ri:ProcessingAbort -v1:%process% & endlocal & exit /b 0

:exec_download
rem если нет каталога дистрибутива модуля, то создаём его
if not exist "!mods[%_mod_name%]#DistribDir!" 1>nul MD "!mods[%_mod_name%]#DistribDir!"

rem выполняем по URL'у загрузку дистрибутива модуля в его каталог
call :download "%curl_%" "!mods[%_mod_name%]#DistribUrl!" "!mods[%_mod_name%]#DistribPath!"

endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem Обеспечивает управляемую установку приложения
rem ---------------------------------------------
:phase_install
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem получаем параметры дистрибуции модуля
call :get_mod_distrib_params "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
rem если не найден дистрибутив модуля
if not exist "!mods[%_mod_name%]#DistribPath!" call :echo -ri:DistribPathExistError -v1:"!mods[%_mod_name%]#DistribPath!" -v2:"%_mod_name%" & endlocal & exit /b 1

rem иначе - пытаемся запросить у пользователя необходимость изменения каталога установки
rem call :get_res_val -rf:"%menus_file%" -ri:ChangeModSetupDir -v1:"%_mod_name%" -v2:"!mods[%_mod_name%]#SetupDir!"
rem call :choice_process "" "" %SHORT_DELAY% N "!res_val!"
rem if ERRORLEVEL %NO% (
rem 	call :echo -ri:InputModSetupDirAbort -v1:"%_mod_name%"
rem ) else (
rem 	call :get_res_val -ri:InputModSetupDir -v1:%_mod_name%
rem	set /p l_new_mod_setup_dir="!res_val!"
rem 	set l_new_mod_setup_dir=!l_new_mod_setup_dir:"=!
rem 	set mods[%_mod_name%]#SetupDir=!l_new_mod_setup_dir!
rem 	call :set_var_value %BV_MOD_SETUP_DIR% "!mods[%_mod_name%]#SetupDir!"
rem )
rem если задан каталог установки модуля и его нет, то создаём его
if "!mods[%_mod_name%]#SetupDir!" NEQ "" if not exist "!mods[%_mod_name%]#SetupDir!" (
	call :echo -ri:CreateModSetupDir -v1:"%_mod_name%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	1>nul MD "!mods[%_mod_name%]#SetupDir!"
	call :echo -ri:ResultOk -rc:0A
)
rem если модуль установлен, переходим к выполнению неявных целей
call :is_mod_installed "%_mod_name%" "%_mod_ver%"
if ERRORLEVEL 1 goto implicit_goals
rem иначе получаем цели фазы установки
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_INSTALL%" goals_cnt
rem разбор по явным целям в порядке следования
for /l %%n in (0,1,%goals_cnt%) do ( 
	set install_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!install_goal!" -ae:1
	if /i "!install_goal!" EQU "%GL_UNPACK_7Z_SFX%" call :goal_unpack_7z_sfx "%_mod_name%"
	if /i "!install_goal!" EQU "%GL_UNPACK_ZIP%" call :goal_unpack_zip "%_mod_name%"
	if /i "!install_goal!" EQU "%GL_SILENT%" call :goal_silent %PH_INSTALL% "%_mod_name%" "%_mod_ver%"
	if /i "!install_goal!" EQU "%GL_CMD_SHELL%" (
		call :get_exec_name "%~0"
		call :goal_cmd_shell "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!exec_name!"
	)
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
:implicit_goals
rem разбор неявных целей
call :goal_add_path_env "%_mod_name%"
if "!mods[%_mod_name%]#HomeEnv!" NEQ "" call :goal_add_env "!mods[%_mod_name%]#HomeEnv!" "!mods[%_mod_name%]#HomeDir!"
set l_result=%ERRORLEVEL%

endlocal & (set "mods[%_mod_name%]#Installed=1" & exit /b %l_result%)

rem ---------------------------------------------
rem Определяет каталоги модуля: установки,
rem исполняемых файлов и домашний
rem (устанавливает: 	mods[%_mod_name%]#SetupDir
rem 			mods[%_mod_name%]#BinDirCnt
rem 			mods[%_mod_name%]#BinDirs[i]
rem 			mods[%_mod_name%]#HomeEnv
rem 			mods[%_mod_name%]#HomeDir)
rem ---------------------------------------------
:get_mod_install_dirs
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
rem получаем каталог установки модуля и его домашний каталог
if not defined mods[%_mod_name%]#SetupDir if not defined mods[%_mod_name%]#HomeDir (
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseConfig -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%PH_INSTALL%
	for /F "tokens=1-3" %%a in ('%xml_sel_% "!res_val!" -v "concat(./modSetupDir, substring('%EMPTY_NODE%', 1 div not(./modSetupDir)))" -o "	" -v "concat(./modHomeDir/envVar, substring('%EMPTY_NODE%', 1 div not(./modHomeDir/envVar)))" -o "	" -v "concat(./modHomeDir/directory, substring('%EMPTY_NODE%', 1 div not(./modHomeDir/directory)))" -n "%g_pkg_cfg_file%"') do (
		if "%%a" NEQ "%EMPTY_NODE%" (
			set mods[%_mod_name%]#SetupDir=%%~a
			call :set_var_value %BV_MOD_SETUP_DIR% "!mods[%_mod_name%]#SetupDir!"
		)
		if "%%b" NEQ "%EMPTY_NODE%" set mods[%_mod_name%]#HomeEnv=%%~b
		if "%%c" NEQ "%EMPTY_NODE%" set mods[%_mod_name%]#HomeDir=%%~c
	)
	if defined mods[%_mod_name%]#SetupDir call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#SetupDir!" mods[%_mod_name%]#SetupDir
	if defined mods[%_mod_name%]#HomeDir call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#HomeDir!" mods[%_mod_name%]#HomeDir
	
	call :echo -ri:ModSetupDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#SetupDir!"
	call :echo -ri:ModHomeDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#HomeEnv!" -v3:"!mods[%_mod_name%]#HomeDir!"
)
rem получаем каталоги бинарных файлов модуля
if not defined mods[%_mod_name%]#BinDirCnt (
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathModBinDirs -v1:"%_mod_name%" -v2:"%_mod_ver%"
	set "i=0"
	for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -n "%g_pkg_cfg_file%"') do (
		set mods[%_mod_name%]#BinDirs[!i!]=%%~a
		set /a "i+=1"
	)
	set /a l_bin_dirs_cnt=!i!-1
	set mods[%_mod_name%]#BinDirCnt=!l_bin_dirs_cnt!
	for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
		call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#BinDirs[%%j]!" mods[%_mod_name%]#BinDirs[%%j]
		call :echo -ri:ModBinDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#BinDirs[%%j]!"
	)
)
exit /b 0

rem ---------------------------------------------
rem Определяет установлен ли уже модуль по:
rem - наличию объектов файловой системы в его каталоге установки
rem - данным реестра
rem (устанавливает: 	mods[%_mod_name%]#Installed)
rem ---------------------------------------------
:is_mod_installed
set _mod_name=%~1
set _mod_ver=%~2

if defined mods[%_mod_name%]#Installed exit /b !mods[%_mod_name%]#Installed!

setlocal
call :echo -ri:CheckModInstalled -v1:"%_mod_name%" -rl:0FILE
if "!mods[%_mod_name%]#SetupDir!" NEQ "" (
	call :echo -ri:CheckModInstalledFS -v1:"!mods[%_mod_name%]#SetupDir!" -rl:0FILE
	if exist "!mods[%_mod_name%]#SetupDir!" for /F "usebackq" %%f IN (`dir "!mods[%_mod_name%]#SetupDir!/" /b /A:`) do (
		call :echo -ri:ResultYes -rl:0FILE
		endlocal & set mods[%_mod_name%]#Installed=1
		exit /b 1
	)
)
call :get_res_val -rf:"%xpaths_file%" -ri:XPathInstallVer -v1:"%_mod_name%" -v2:"%_mod_ver%"
for /F "tokens=1,2" %%i in ('%xml_sel_% "!res_val!" -v "./regKey" -o "	" -v "./regParam" -n "%g_pkg_cfg_file%"') do (
        set l_regKey=%%i
	set l_regParam=%%j
	call :echo -ri:CheckModInstalledReg -v1:"!l_regKey!" -v2:"!l_regParam!" -rl:0FILE
	call :reg -oc:%RC_GET% -kn:"!l_regKey!" -vn:"!l_regParam!"
	if "!reg!" NEQ "" (
		call :echo -ri:ResultYes -rl:0FILE
		call :echo -ri:RegModVersion -v1:"%_mod_name%" -v2:"!reg!" -rl:0FILE
		endlocal & set mods[%_mod_name%]#Installed=1
		exit /b 1
	)
)
call :echo -ri:ResultNo -rl:0FILE
endlocal & set mods[%_mod_name%]#Installed=0
exit /b 0

rem ---------------------------------------------
rem Получает цели заданной фазы
rem Возвращает: goals_cnt
rem (устанавливает: 	phase_goals[x])
rem ---------------------------------------------
:get_phase_goals _mod_name _mod_ver _phase goals_cnt
set _mod_name=%~1
set _mod_ver=%~2
set _phase=%~3

rem получаем цели фазы установки
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseGoals -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_phase%"
set "x=0"
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./goal" -n "%g_pkg_cfg_file%"') do (
	set phase_goals[!x!]=%%a
	set /a "x+=1"
)
set /a "x-=1"
set %4=%x%
exit /b 0

rem ---------------------------------------------
rem Выполняет действия с уже установленным модулем
rem ---------------------------------------------
:execute_choice
set _exec_choice=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4

set l_delay=%DEF_DELAY%
set l_choice=
call :echo -rf:"%menus_file%" -ri:ExecModChoice -v1:"%_mod_name%" -v2:%l_delay% -rc:0E -be:1
rem получаем фазы выполнения
call :get_mod_phases "%_mod_name%" "%_mod_ver%"
rem разбор по явным целям в порядке следования
set "x=1" 
for /l %%n in (0,1,!mods[%_mod_name%]#PhaseCnt!) do ( 
	set l_mod_choice[!x!]#Phase=!mods[%_mod_name%]#Phase[%%n]@Name!
	set l_mod_choice[!x!]#Id=!mods[%_mod_name%]#Phase[%%n]@Id!
	
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_INSTALL%" (
		call :echo -rf:"%menus_file%" -ri:RepairModSetup -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_CONFIG%" (
		call :echo -rf:"%menus_file%" -ri:ApplyModConfig -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_BACKUP%" (
		call :echo -rf:"%menus_file%" -ri:BackupRestore -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_UNINSTALL%" (
		set "l_phase_uninstall_id=!mods[%_mod_name%]#Phase[%%n]@Id!"
		set "phase_uninstall_exist=%VL_TRUE%"
	)
)
rem предлагаем деинсталляцию по умолчанию
set l_mod_choice[!x!]#Phase=%PH_UNINSTALL%
if defined l_phase_uninstall_id (
	set l_mod_choice[!x!]#Id=!l_phase_uninstall_id!
) else (
	set l_mod_choice[!x!]#Id=%_mod_name%-%PH_UNINSTALL% [%PH_INSTALL%]
)
set l_phase_uninstall_id=
set l_choice=!l_choice!!x!
call :echo -rf:"%menus_file%" -ri:UninstallMod -v1:%x% -rc:0F -rs:8

set /a "x+=1"
set l_choice=!l_choice!!x!
call :echo -rf:"%menus_file%" -ri:ActionNo -v1:%x% -rc:0F -rs:8 -ae:1

rem если определён выбор выполнения по умолчанию
if "%_exec_choice%" NEQ "" set "exec_num=%_exec_choice%" & goto execute_def

call :get_res_val -rf:"%menus_file%" -ri:ChoiceModExec
call :choice_process "" "" %l_delay% %x% "%res_val%" "%l_choice%"
set exec_num=%ERRORLEVEL%

if %exec_num% GEQ %x% exit /b 0

:execute_def
for /f "usebackq delims==# tokens=1-3,*" %%j in (`set l_mod_choice[%exec_num%]`) do (
	rem echo %%j %%k %%l
	set l_mod_choice_cur#%%k=%%l%%m
) 
call :echo -ri:ExecPhaseId -v1:"%l_mod_choice_cur#Id%" -ae:1
rem если выбрано "Исправление установки", то не запрашиваем разрешение выполнения фазы
if /i "%l_mod_choice_cur#Phase%" EQU "%PH_INSTALL%" goto continue_execute_choice

call :choice_process "%l_mod_choice_cur#Phase%" ProcessingPhase
if ERRORLEVEL %NO% call :echo -ri:PhaseExecAbort -v1:"%l_mod_choice_cur#Phase%" & exit /b 0

:continue_execute_choice
if /i "%l_mod_choice_cur#Phase%" EQU "%PH_INSTALL%" (
	rem выполняем все фазы модуля
	call :execute_mod_phases "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_CONFIG%" (
	call :phase_config "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_BACKUP%" (
	call :phase_backup "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_UNINSTALL%" (
	rem получаем каталог установки модуля, его каталог бинарных файлов и домашний каталог
rem	call :get_mod_install_dirs "%_mod_name%" "%_mod_ver%"
	rem каталоги гарантированно получены ранее до вызова текущей процедуры

	rem если есть фаза деинсталляции, то выполяем деинсталляцию по ней, иначе - по фазе инсталляции
	if /i "%phase_uninstall_exist%" EQU "%VL_TRUE%" (
		call :phase_uninstall "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
	) else (
		call :phase_module_uninstall "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
	)
)
if ERRORLEVEL 1 exit /b %ERRORLEVEL%
exit /b 0

rem ---------------------------------------------
rem Применяет конфигурацию заданного модуля
rem ---------------------------------------------
:phase_config
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem предвыполнение неявных целей
call :goal_backup_config "%_mod_name%" "%_mod_ver%"

rem получаем цели фазы конфигурации
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_CONFIG%" goals_cnt

rem разбор по явным целям в порядке следования
for /l %%n in (0,1,%goals_cnt%) do ( 
	set config_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!config_goal!" & echo.
	if /i "!config_goal!" EQU "%GL_CMD_SHELL%" (
		call :get_exec_name "%~0"
		call :goal_cmd_shell "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!exec_name!"
	)
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
rem поствыполнение неявных целей
rem получаем имя и комментирующий символ конфигурационного файла модуля
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCfgFile -v1:"%_mod_name%" -v2:"%_mod_ver%"
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	" -v "./comment" -n "%g_pkg_cfg_file%"') do (
	set l_config_file=%%a
	set l_comment=%%b
	call :goal_apply_cfg_prms "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!l_config_file!" "!l_comment!"
)
endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem Резервирует/восстановливает данные модуля
rem ---------------------------------------------
:phase_backup
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

call :echo -ri:DefFuncNotImpl -v1:"%~0" & endlocal & exit /b 0

call :echo -ri:AddPathEnv -v1:%_dir% -rc:0F -ln:%VL_FALSE%
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Деинсталлирует модуль согласно фазе деинсталляции
rem ---------------------------------------------
:phase_uninstall
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem получаем цели фазы деинсталляции
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_UNINSTALL%" goals_cnt
rem разбор по явным целям в порядке следования
for /l %%n in (0,1,%goals_cnt%) do ( 
	set uninstall_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!uninstall_goal!" -ae:1
	if /i "!uninstall_goal!" EQU "%GL_UNINSTALL_PORTABLE%" call :goal_uninstall_portable "%_mod_name%"
	if /i "!uninstall_goal!" EQU "%GL_SILENT%" call :goal_silent %PH_UNINSTALL% "%_mod_name%" "%_mod_ver%"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
rem разбор неявных целей
call :goal_del_path_env "%_mod_name%"
if defined mods[%_mod_name%]#HomeEnv call :goal_del_env "!mods[%_mod_name%]#HomeEnv!"
set l_result=%ERRORLEVEL%

endlocal & (set "mods[%_mod_name%]#Installed=0" & exit /b %l_result%)

rem ---------------------------------------------
rem Деинсталлирует модуль согласно фазе инсталляции
rem ---------------------------------------------
:phase_module_uninstall
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem получаем цели фазы установки
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_INSTALL%" goals_cnt

rem разбор неявных целей
call :goal_del_path_env "%_mod_name%"
if defined mods[%_mod_name%]#HomeEnv call :goal_del_env "!mods[%_mod_name%]#HomeEnv!"
set l_result=%ERRORLEVEL%

rem разбор по явным целям в обратном порядке
for /l %%n in (%goals_cnt%,-1,0) do ( 
	set uninstall_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!uninstall_goal!"
	if /i "!uninstall_goal!" EQU "%GL_UNPACK_7Z_SFX%" call :goal_uninstall_portable "%_mod_name%"
	if /i "!uninstall_goal!" EQU "%GL_UNPACK_ZIP%" call :goal_uninstall_portable "%_mod_name%"
	if /i "!uninstall_goal!" EQU "%GL_SILENT%" call :goal_silent %PH_UNINSTALL% "%_mod_name%" "%_mod_ver%"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 

endlocal & (set "mods[%_mod_name%]#Installed=0" & exit /b %l_result%)

rem ====================================================================================================================
rem ЦЕЛИ:
rem ====================================================================================================================

rem ---------------------------------------------
rem Распаковывает 7-zip самораспаковывающийся архив
rem ---------------------------------------------
:goal_unpack_7z_sfx
setlocal
set _mod_name=%~1

rem КОНТРОЛЬ: не задан или отсутствует каталог установки
if "!mods[%_mod_name%]#SetupDir!" EQU "" call :echo -ri:ModSetupDirParamError -v1:"%_mod_name%" & endlocal & exit /b 1
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:Unpack7zSfx -v1:!mods[%_mod_name%]#DistribFile! -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%

call :get_res_val -ri:UnpackDistribFile -v1:"!mods[%_mod_name%]#DistribFile!"
start "%res_val%" /D "!mods[%_mod_name%]#SetupDir!" /WAIT "!mods[%_mod_name%]#DistribPath!" -y
rem -gm2 -InstallPath="!mods[%_mod_name%]#SetupDir!"
rem -y -o"!mods[%_mod_name%]#SetupDir!"
call :echo -ri:ResultOk -rc:0A

call :echo -ri:DefUnpackDir -rc:0F -ln:%VL_FALSE%
rem так как распаковка выполняется в каталог дистрибутива, то считаем, сколько в нём каталогов и файлов, кроме самого дистрибутива
pushd "!mods[%_mod_name%]#DistribDir!" 
set "x=0" 
for /F %%i in ('dir * /b') do if /i "%%i" NEQ "!mods[%_mod_name%]#DistribFile!" set /a "x+=1" & set l_src_obj=%%i
rem echo %x% %l_src_obj%
call :echo -ri:ResultOk -rc:0A
rem если требуется перенести содержимое только одного каталога
if %x% EQU 1 (
	call :echo -ri:MoveModDistribSetupDir -v1:"!mods[%_mod_name%]#DistribDir!%DIR_SEP%%l_src_obj%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	1>nul %copy_% "!mods[%_mod_name%]#DistribDir!%DIR_SEP%%l_src_obj%" "!mods[%_mod_name%]#SetupDir!" /E /MOVE
	call :echo -ri:ResultOk -rc:0A
) else if %x% GTR 1 (
	rem иначе переносим все каталоги и файлы, кроме дистрибутива
	call :echo -ri:MoveUnpackSetupDir -v1:"!mods[%_mod_name%]#DistribDir!" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	for /F %%i in ('dir * /b') do if /i "%%i" NEQ "!mods[%_mod_name%]#DistribFile!" 1>nul move "!mods[%_mod_name%]#DistribDir!\%%i" "!mods[%_mod_name%]#SetupDir!"
	call :echo -ri:ResultOk -rc:0A
)
popd
endlocal & exit /b 0

rem ---------------------------------------------
rem Тихая инсталляция/деинсталляция дистрибутива
rem ---------------------------------------------
:goal_silent
setlocal
set _phase=%~1
set _mod_name=%~2
set _mod_ver=%~3

if /i "%_phase%" EQU "%PH_INSTALL%" (
	call :echo -ri:SilentInstall -v1:!mods[%_mod_name%]#DistribFile! -rc:0F -ln:%VL_FALSE%
	call :get_res_val -ri:InstallDistribFile -v1:"!mods[%_mod_name%]#DistribFile!" & set goal_title=!res_val!
)
if /i "%_phase%" EQU "%PH_UNINSTALL%" (
	call :echo -ri:SilentUninstall -v1:%_mod_name% -rc:0F -ln:%VL_FALSE%
	call :get_res_val -ri:UninstallDistribFile -v1:"!mods[%_mod_name%]#DistribFile!" & set goal_title=!res_val!
)
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseConfig -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%_phase%
for /F "tokens=*" %%a in ('%xml_sel_% "!res_val!" -v "./keys" -n "%g_pkg_cfg_file%"') do (
	set l_keys=%%a
)
call :echo -ri:SilentKeys -v1:!mods[%_mod_name%]#DistribFile! -v2:"%l_keys%"

echo start "%goal_title%" /WAIT "!mods[%_mod_name%]#DistribPath!" "%l_keys%"

call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0

rem ---------------------------------------------
rem Распаковывает zip-архив
rem ---------------------------------------------
:goal_unpack_zip
setlocal
set _mod_name=%~1

rem КОНТРОЛЬ: не задан или отсутствует каталог установки
if "!mods[%_mod_name%]#SetupDir!" EQU "" call :echo -ri:ModSetupDirParamError -v1:"%_mod_name%" & endlocal & exit /b 1
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:UnpackZip -v1:!mods[%_mod_name%]#DistribFile! -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%

call :get_exec_name "%~0"
call :get_res_val -ri:UnpackDistribFile -v1:"!mods[%_mod_name%]#DistribFile!"
start "%res_val%" /WAIT "%z7_%" x "!mods[%_mod_name%]#DistribPath!" -o"!mods[%_mod_name%]#SetupDir!" -r 1> "%bis_log_dir%%DIR_SEP%%_mod_name%-%exec_name%.log" 2>&1

call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0

rem ---------------------------------------------
rem Удаляет каталог портативного приложения
rem ---------------------------------------------
:goal_uninstall_portable
setlocal
set _mod_name=%~1

rem если есть каталог установки модуля, то удаляем его
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:DelModSetupDir -v1:"%_mod_name%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F

call :choice_process "%~0" DelExistModSetupDir %DEF_DELAY% N
if ERRORLEVEL %NO% call :echo -ri:ProcessingAbort -v1:%process% & endlocal & exit /b 0

1>nul RD /S /Q "!mods[%_mod_name%]#SetupDir!"
call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0

rem ---------------------------------------------
rem Добавляет заданный путь в переменную среды PATH
rem (определяет похожие пути и запрашивает разрешение 
rem на их удаление)
rem ---------------------------------------------
:goal_add_path_env
setlocal
set _mod_name=%~1

call :print_exec_name "%~0"
rem если хотя бы один каталог не существует, то ни один не добавляем
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	if not exist "!mods[%_mod_name%]#BinDirs[%%j]!" call :echo -ri:PathDirExistError -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" & endlocal & exit /b 1
)
rem поиск и ручное удаление похожих существующих путей
call :get_reg_value "" "%RH_HKCU%" PATH
set l_paths=!reg_value!
:paths_loop
for /f "tokens=1* delims=;" %%i in ("%l_paths%") do (
	set l_path=%%i
	set "$check_path=!l_path:%_mod_name%=!"
	if /i "!$check_path!" NEQ "!l_path!" (
		call :get_res_val -rf:"%menus_file%" -ri:ExistModPathEnv -v1:"%_mod_name%" -v2:"!l_path!" -v3:%DEF_DELAY%
		call :choice_process "" "" %DEF_DELAY% N "!res_val!"
		if !choice! EQU %YES% (
			call :echo -ri:DelPathEnv -v1:"!l_path!" -rc:0F -ln:%VL_FALSE%
			call :reg -oc:%RC_DEL% -vn:PATH -vv:"!l_path!"
			call :echo -ri:ResultOk -rc:0A
		)
	)
	set l_paths=%%j
)
if defined l_paths goto :paths_loop
rem добавление путей
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	call :echo -ri:AddPathEnv -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" -rc:0F -ln:%VL_FALSE%
	rem call :convert_case %CM_LOWER% "!mods[%_mod_name%]#BinDirs[%%j]!" l_bin_dir
	call :convert_slashes %CSD_WIN% "!mods[%_mod_name%]#BinDirs[%%j]!" l_bin_dir
	call :reg -oc:%RC_ADD% -vn:PATH -vv:"!l_bin_dir!"
	call :echo -ri:ResultOk -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Удаляет заданный путь из переменной среды PATH
rem ---------------------------------------------
:goal_del_path_env
setlocal
set _mod_name=%~1

call :print_exec_name "%~0"

for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	call :echo -ri:DelPathEnv -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" -rc:0F -ln:%VL_FALSE%
	rem call :convert_case %CM_LOWER% "!mods[%_mod_name%]#BinDirs[%%j]!" l_bin_dir
	call :convert_slashes %CSD_WIN% "!mods[%_mod_name%]#BinDirs[%%j]!" l_bin_dir
	call :reg -oc:%RC_DEL% -vn:PATH -vv:"!l_bin_dir!"
	call :echo -ri:ResultOk -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Добавляет переменную среды с заданным значением
rem ---------------------------------------------
:goal_add_env
setlocal
set _env=%~1
set _val=%~2

call :print_exec_name "%~0"

call :echo -ri:AddEnv -v1:"%_env%" -v2:"%_val%" -rc:0F -ln:%VL_FALSE%
call :convert_slashes %CSD_WIN% "%_val%" _val
rem call :reg -oc:%RC_SET% -vn:"%_env%" -vv:"%_val%"
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Удаляет переменную среды с заданным именем
rem ---------------------------------------------
:goal_del_env
setlocal
set _env=%~1

call :print_exec_name "%~0"

call :echo -ri:DelEnv -v1:"%_env%" -rc:0F -ln:%VL_FALSE%
rem call :reg -oc:%RC_DEL% -vn:"%_env%"
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Выполняет команды командного процессора
rem ---------------------------------------------
:goal_cmd_shell
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
rem получаем команды процессора
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdCommands -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%"
set "copy_num=0"
set "move_num=0"
set "md_num=0"
for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "name()" -n "%g_pkg_cfg_file%"') do (
	set l_cmd=%%a
	if /i "!l_cmd!" EQU "COPY" set /a "copy_num+=1" & call :cmd_copy "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" !copy_num!
	if /i "!l_cmd!" EQU "MOVE" set /a "move_num+=1" & call :cmd_move "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" !move_num!
	if /i "!l_cmd!" EQU "MD" set /a "md_num+=1" & call :cmd_md "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" !md_num!
	if /i "!l_cmd!" EQU "BATCH" call :cmd_batch "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%"
)
endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem Копирует заданные объекты файловой системы из 
rem каталога источника в каталог назначения
rem ---------------------------------------------
:cmd_copy
setlocal EnableExtensions EnableDelayedExpansion
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
set _copy_num=%~5

call :echo -ri:CmdCopy -rc:0F -ln:%VL_FALSE%

rem получаем пути файлов источников
call :get_cmd_objects XPathCmdCopySrc "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_copy_num% l_src_dir l_src_paths src_cnt

rem получаем пути файлов назначения
call :get_cmd_objects XPathCmdCopyDst "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_copy_num% l_dst_dir l_dst_paths dst_cnt

rem КОНТРОЛЬ:
call :get_exec_name "%~0"
call :validate_src_dst_cnts "!exec_name!" %src_cnt% %dst_cnt%
if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

rem ВЫПОЛНЕНИЕ:
rem если указаны только каталог источник и каталог назначения
if %src_cnt% EQU -1 if %dst_cnt% EQU -1 (
	call :echo -ri:CmdCopyMoveObjects -v1:"%l_src_dir%" -v2:"%l_dst_dir%"
	if not exist "%l_src_dir%" call :echo -ri:SrcDirExistError -v1:"%l_src_dir%" & endlocal & exit /b 1
	1>nul %copy_% "%l_src_dir%" "%l_dst_dir%" /E
	call :echo -ri:ResultCountOk -v1:1 -rc:0A
)
rem если указаны файлы источники и каталог назначения
if %src_cnt% GTR -1 if %dst_cnt% EQU -1 (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"%l_dst_dir%"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		if not exist "%l_dst_dir%" call :echo -ri:DstDirExistError -v1:"%l_dst_dir%" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "%l_dst_dir%" l_dst_dir
		1>nul copy /y "!l_src_paths[%%n]!" "!l_dst_dir!"
	)
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
) 
rem если указаны файлы источники и соответствующее кол-во файлов назначения
if %src_cnt% GTR -1 if %dst_cnt% EQU %src_cnt% (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul copy /y "!l_src_paths[%%n]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
rem если указан один файл источник и несколько файлов назначения
if %src_cnt% EQU 0 if %dst_cnt% GTR %src_cnt% (
	call :convert_slashes %CSD_WIN% "!l_src_paths[0]!" l_src_paths[0]
	for /l %%n in (0,1,%dst_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[0]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[0]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[0]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul copy /y "!l_src_paths[0]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%dst_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Перемещает заданные объекты файловой системы из 
rem каталога источника в каталог назначения
rem ---------------------------------------------
:cmd_move
setlocal EnableExtensions EnableDelayedExpansion
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
set _move_num=%~5

call :echo -ri:CmdMove -rc:0F -ln:%VL_FALSE%

rem получаем пути файлов источников
call :get_cmd_objects XPathCmdCopySrc "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_move_num% l_src_dir l_src_paths src_cnt

rem получаем пути файлов назначения
call :get_cmd_objects XPathCmdCopyDst "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_move_num% l_dst_dir l_dst_paths dst_cnt

rem КОНТРОЛЬ:
call :get_exec_name "%~0"
call :validate_src_dst_cnts "!exec_name!" %src_cnt% %dst_cnt%
if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

rem ВЫПОЛНЕНИЕ:
rem если указаны только каталог источник и каталог назначения
if %src_cnt% EQU -1 if %dst_cnt% EQU -1 (
	call :echo -ri:CmdCopyMoveObjects -v1:"%l_src_dir%" -v2:"%l_dst_dir%"
	if not exist "%l_src_dir%" call :echo -ri:SrcDirExistError -v1:"%l_src_dir%" & endlocal & exit /b 1
	1>nul %copy_% "%l_src_dir%" "%l_dst_dir%" /E /MOVE
	call :echo -ri:ResultCountOk -v1:1 -rc:0A
)
rem если указаны файлы источники и каталог назначения
if %src_cnt% GTR -1 if %dst_cnt% EQU -1 (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"%l_dst_dir%"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		if not exist "%l_dst_dir%" call :echo -ri:DstDirExistError -v1:"%l_dst_dir%" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "%l_dst_dir%" l_dst_dir
		1>nul move /y "!l_src_paths[%%n]!" "!l_dst_dir!"
	)
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
) 
rem если указаны файлы источники и соответствующее кол-во файлов назначения
if %src_cnt% GTR -1 if %dst_cnt% EQU %src_cnt% (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul move /y "!l_src_paths[%%n]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Создаёт заданные в конфигурации каталоги
rem ---------------------------------------------
:cmd_md
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
set _md_num=%~5

call :echo -ri:CmdMd -rc:0F -ln:%VL_FALSE%
rem получаем каталоги
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdMdDirs -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%" -v4:%_md_num%
set "i=0"
for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -n "%g_pkg_cfg_file%"') do (
	set l_dir=%%~a
	call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" l_dir
	rem if not exist "!l_dir!" 1>nul MD "!l_dir!" & call :echo -ri:CmdCopyMoveObjects -v1:"!l_dir!"
	set /a "i+=1"
)
call :echo -ri:ResultCountOk -v1:%i% -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Выполняет системные команды
rem ---------------------------------------------
:cmd_batch
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4

call :echo -ri:CmdBatch -rc:0F
rem -ln:%VL_FALSE%
rem получаем команды
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdBatch -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%"
set "i=0"
for /F "tokens=*" %%a in ('%xml_sel_% "!res_val!" -v "./exec" -n "%g_pkg_cfg_file%"') do (
	set l_exec_cmd=%%~a
	call :binding_var "" "" "!l_exec_cmd!" l_exec_cmd
	if !ERRORLEVEL! EQU 0 (
		call :echo -ri:CmdBatchExec -v1:"!l_exec_cmd!" -ln:%VL_FALSE% -rl:5FINE
		call !l_exec_cmd!
		set l_exec_res=!ERRORLEVEL!
		if !l_exec_res! NEQ 0 (
			call :echo -ri:ResultFailNum -v1:"!l_exec_res!" -rl:5FINE
		) else (
			call :echo -ri:ResultOk -rc:0A -rl:5FINE
		)
		set /a "i+=1"
	)
)
call :echo -ri:ResultCountOk -v1:%i% -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает объекты источники или назначения
rem командной оболочки (cmd-shell)
rem ---------------------------------------------
:get_cmd_objects
set _res_id=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4
set _exec_name=%~5
set _cmd_num=%~6

set "i=0"
rem set /a "%9=%i%-1"
call :get_res_val -rf:"%xpaths_file%" -ri:%_res_id% -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%" -v4:%_cmd_num%
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -o "	" -v "./includes/include" -n "%g_pkg_cfg_file%"') do (
	set l_dir=%%a
	set l_file=%%b

	if "!l_file!" EQU "" call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" %7 & exit /b 0
	if "!l_file!" EQU "*" call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" %7 & exit /b 0

	set "%8[!i!]=!l_dir!%DIR_SEP%!l_file!"
	set /a "i+=1"
)
set /a "%9=%i%-1"
for /l %%n in (0,1,%9) do call :binding_var "%_pkg_name%" "%_mod_name%" "!%8[%%n]!" %8[%%n]
exit /b 0

rem ---------------------------------------------
rem Проверяет корректность количества объектов источников
rem и объектов назначения файловой системы (cmd-shell)
rem ---------------------------------------------
:validate_src_dst_cnts
setlocal
set _exec_name=%~1
set _src_cnt=%~2
set _dst_cnt=%~3

rem если не указаны файлы источники, но указаны файлы назначения, то ошибка
if %_src_cnt% EQU -1 if %_dst_cnt% NEQ -1 call :echo -ri:CmdSrcEmptyError -v1:%_dst_cnt% -v2:"%_exec_name%" & endlocal & exit /b 1
rem если кол-во источников один и более (> -1) и не равно кол-ву назначений, при кол-во назначений > -1, то ошибка
if %_src_cnt% GTR -1 if %_dst_cnt% GTR -1 if %_src_cnt% NEQ %_dst_cnt% call :echo -ri:CmdSrcNeqDstError -v1:%_src_cnt% -v2:%_dst_cnt% -v3:"%_exec_name%" & endlocal & exit /b 1
endlocal & exit /b 0

rem ---------------------------------------------
rem Применяет параметры конфигурационного файла
rem ---------------------------------------------
:goal_apply_cfg_prms
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _pkg_cfg_file=%~4
set _cfg_cmt=%~5

call :binding_var "%_pkg_name%" "%_mod_name%" "%_pkg_cfg_file%" l_mod_cfg_path
call :echo -ri:ApplyCfgParams -v1:"%l_mod_cfg_path%" -rc:0F -ln:%VL_FALSE%

rem формируем путь к временной копии конфигурационного файла модуля
for /f %%i in ("%l_mod_cfg_path%") do set l_cfg_file_name=%%~nxi
set l_tmp_file="%TMP%%DIR_SEP%%l_cfg_file_name%.tmp"
type NUL > "%l_tmp_file%"

call :echo -ri:CreatedCfgTmpFile -v1:"%l_tmp_file%"

if "%_cfg_cmt%" NEQ "" call :len "%_cfg_cmt%" l_cmt_len
rem получаем параметры конфигурационного файла модуля
set "i=0"
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCfgParams -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_pkg_cfg_file%"
rem for /F "tokens=1-8" %%a in ('%xml_sel_% "!xpath_cfg_prms!" -v "./name" -o "	" -v "./value" -o "	" -v "./description" -o "	" -v "./expression" -o "	" -v "./after" -o "	" -v "./before" -o "	" -v "./quotes" -o "	" -v "./entry" -n "%g_pkg_cfg_file%"') do (
for /F "tokens=1-6" %%a in ('%xml_sel_% "!res_val!" -v "concat(./name, substring('%EMPTY_NODE%', 1 div not(./name)))" -o "	" -v "./value" -o "	" -v "concat(./expression, substring('%EMPTY_NODE%', 1 div not(./expression)))" -o "	" -v "concat(./after, substring('%EMPTY_NODE%', 1 div not(./after)))" -o "	" -v "concat(./before, substring('%EMPTY_NODE%', 1 div not(./before)))" -o "	" -v "concat(./entry, substring('%EMPTY_NODE%', 1 div not(./entry)))" -n "%g_pkg_cfg_file%"') do (
	if "%%a" NEQ "%EMPTY_NODE%" set l_prms[!i!]#Name=%%~a
	set l_prms[!i!]#Val=%%b
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%a" 2^>nul`) DO set l_prms[!i!]#CaseName=%%A
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%b" 2^>nul`) DO set l_prms[!i!]#CaseVal=%%A
	rem set l_prms[!i!]#Descr=%%c
	if "%%c" NEQ "%EMPTY_NODE%" set l_prms[!i!]#Exp=%%~c
	if "%%d" NEQ "%EMPTY_NODE%" set l_prms[!i!]#After=%%~d
	if "%%e" NEQ "%EMPTY_NODE%" set l_prms[!i!]#Before=%%~e
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%e" 2^>nul`) DO set l_prms[!i!]#CaseAfter=%%A
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%f" 2^>nul`) DO set l_prms[!i!]#CaseBefore=%%A
	if "%%f" NEQ "%EMPTY_NODE%" (set l_prms[!i!]#Entry=%%~f) else (set l_prms[!i!]#Entry=1)
	set l_prms[!i!]#CurEntry=0
	set l_prms[!i!]#Applied=0
	set l_prms[!i!]#Multiple=0
	call :get_pval "%_pkg_name%" "%_mod_name%" !i!
	set l_prms[!i!]#PrmVal=!pval!
	set /a "i+=1"
	rem echo %%~a	%%b	%%~c	%%~d	%%~e	%%~f
)
set /a "prms_cnt=%i%-1"
call :echo -ri:NeedApplyParamsCnt -v1:%i%
rem отмечаем множественные параметры
for /l %%j in (0,1,%prms_cnt%) do (
	if "!l_prms[%%j]#Name!" NEQ "" (
		if !l_prms[%%j]#Multiple! EQU 0 (
			for /l %%k in (0,1,%prms_cnt%) do (
				if %%j NEQ %%k (
					if !l_prms[%%k]#Multiple! EQU 0 if /i "!l_prms[%%j]#Name!" EQU "!l_prms[%%k]#Name!" (
						set l_prms[%%j]#Multiple=1
						set l_prms[%%k]#Multiple=1
					)
				)
			)
		)
	)
)
rem for /l %%j in (0,1,%prms_cnt%) do echo !l_prms[%%j]#PrmVal! - !l_prms[%%j]#Multiple!
rem exit
rem если есть параметр для применения, то вычитываем строки конфигурационного файла модуля
if %prms_cnt% GEQ 0 (
	set "i=-1"
	rem обработка параметров
	for /F "usebackq eol= delims=" %%l in ("%l_mod_cfg_path%") do (
		set l_ln=%%l
		set is_applied=0
		set is_find=0
		rem первый цикл поиска параметров в строке
		for /l %%j in (0,1,%prms_cnt%) do (
			if !l_prms[%%j]#Applied! EQU 0 (
echo 1
				call :find_prm_in_ln "#Name" %%j "%_cfg_cmt%" %l_cmt_len%
				rem если строка содержит искомый параметр
				if NOT ERRORLEVEL 3 (
echo 2
					rem если требуется дополнительная проверка, проверяем наличие имени и значения параметра
					if ERRORLEVEL 2 call :find_cmt_pval "%_pkg_name%" "%_mod_name%" %%j "%_cfg_cmt%"
echo 3
					rem если выполнилась проверка по "имени"-"значению"
					if NOT ERRORLEVEL 3 (
echo 3.5
						rem если строка содержит его "чисто" или в закомментированном виде, то применяем его
						if ERRORLEVEL 1 (
							set /a "l_prms[%%j]#CurEntry+=1"
echo 4 entry: !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry!
							if !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry! (
echo 5
								call :apply_prm "%_pkg_name%" "%_mod_name%" "#Name" %%j "%l_tmp_file%"
								set l_prms[%%j]#Applied=1
								set is_applied=1
								set /a "i+=1"
							)
						)
						set is_find=1
					)
				)
			)
		)
echo 6
		rem второй цикл поиска параметров в строке
		rem если параметр содержится в строке, но не удалось его применить по значению, пытаемся найти по имени
echo is_applied = !is_applied!; is_find = !is_find!
		if !is_applied! EQU 0 if !is_find! EQU 1 (
			for /l %%j in (0,1,%prms_cnt%) do (
				rem если параметр не множественный и не применён
				if !l_prms[%%j]#Multiple! EQU 0 if !is_applied! EQU 0 if !l_prms[%%j]#Applied! EQU 0 (
echo 7
					rem то находим его в закомментированной строке по имени
					call :find_cmt_pname %%j "%_cfg_cmt%"
					rem если нашли по "имени"
					if NOT ERRORLEVEL 3 (
						rem если закомментированная строка содержит имя параметра
						if ERRORLEVEL 1 (
							set /a "l_prms[%%j]#CurEntry+=1"
echo 8 entry: !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry!
							if !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry! (
echo 9
								call :apply_prm "%_pkg_name%" "%_mod_name%" "#Name" %%j "%l_tmp_file%"
								set l_prms[%%j]#Applied=1
								set is_applied=1
								set /a "i+=1"
							)
						)
					)
				)
			)
		)
echo 10
		rem если к текущей строке не применён ни один искомый параметр, то пишем её в файл
echo is_applied = !is_applied!
		if !is_applied! EQU 0 echo !l_ln!>>"%l_tmp_file%"
	)
echo 11
	echo %prms_cnt%  - !i!
	if !i! EQU %prms_cnt% goto all_prm_applied
	rem записываем в конец временного файла неприменённые параметры
echo 12
	set "k=0"
	for /l %%j in (0,1,%prms_cnt%) do (
		rem если у них не определены параметры "перед" или "после"
		if !l_prms[%%j]#Applied! EQU 0 if "!l_prms[%%j]#After!" EQU "" if "!l_prms[%%j]#Before!" EQU "" (
echo 13
			call :get_pval "%_pkg_name%" "%_mod_name%" %%j
			echo !pval!>>"%l_tmp_file%"
			set l_prms[%%j]#Applied=1
			set /a "k+=1"
			set /a "i+=1"
		)
	)
	call :echo -ri:AddCfgParamsCnt -v1:!k!
	rem Заменяем текущий файл конфигурации модуля временной копией
	rem 1>nul copy "%l_tmp_file%" "%l_mod_cfg_path%"
	echo %prms_cnt%  - !i!
	rem если параметров больше, чем применено "в лоб"
	if %prms_cnt% GTR !i! (
	exit
		rem type NUL > "%l_tmp_file%"
		rem применяем остальные вторым прогоном согласно параметрам "перед" или "после"
		for /F "usebackq eol= delims=" %%a in ("%l_mod_cfg_path%") do (
			set l_ln=%%a
			set is_applied=0
			for /l %%j in (0,1,%prms_cnt%) do (
				if !l_prms[%%j]#Applied! EQU 0 (
					call :find_prm_in_ln "#After" %%j "%_cfg_cmt%" %l_cmt_len%
					rem если строка содержит искомый параметр
					if NOT ERRORLEVEL 2 (
						rem если содержит его "чисто", то применяем его
						if ERRORLEVEL 1 (
							call :apply_prm "%_pkg_name%" "%_mod_name%" "#After" %%j "%l_tmp_file%"
							set l_prms[%%j]#Applied=1
							set is_applied=1
							set /a "i+=1"
						)
					)
				)
			)
			
			rem если к строке не применён ни один искомый параметр, то пишем её в файл
			if !is_applied! EQU 0 echo !l_ln!>>"%l_tmp_file%"
		)
		rem Заменяем текущий файл конфигурации модуля временной копией
		rem 1>nul copy "%l_tmp_file%" "%l_mod_cfg_path%"
	)
	echo %prms_cnt%  - !i!
)
:all_prm_applied
exit
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает признак наличия параметра в строке
rem ---------------------------------------------
:find_prm_in_ln
setlocal
set _find=%~1
set _j=%~2
set _cfg_cmt=%~3
set _cmt_len=%~4

rem определяем проверяемый на наличие параметр			
if "!l_prms[%_j%]%_find%!" NEQ "" (
	set l_chk_pname=!l_prms[%_j%]%_find%!
) else if "!l_prms[%_j%]#After!" NEQ "" (
	set l_chk_pname=!l_prms[%_j%]#After!
) else (
	set l_chk_pname=!l_prms[%_j%]#Before!
)
rem контроль по имени параметра (с учётом: возможного символа комментария - %%a, имени параметра - %%b 
rem символа "=" - %%c и его значения - %%d). При условии наличия комментария или выражения
if "%_cfg_cmt%" NEQ "" set l_cmts=!CMT_SYMBS:%_cfg_cmt%=!
set l_cmts=%l_cmts:"=%
if "!l_ln:~0,%_cmt_len%!" EQU "%_cfg_cmt%" (
	if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
		for /F "eol= tokens=1-3 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b%%c"
	) else (
		for /F "eol= tokens=1-4 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b%%c%%d"
	)
) else (
	if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
		for /F "eol= tokens=1,2 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b"
	) else (
		for /F "eol= tokens=1-3 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b%%c"
	)
)
set l_ln_pname=%l_ln_pname:"=%
set "$ln=!l_ln_pname:%l_chk_pname%=!"

echo "%$ln%" "%l_ln_pname%" "!l_chk_pname!"
rem если не удалось получить имя параметра из строки или строка не содержит искомый параметр, то возвращаем 3
if /i "%l_ln_pname%" EQU "" endlocal & exit /b 3
if /i "%$ln%" EQU "!l_ln_pname!" endlocal & exit /b 3

echo 14
rem Если не задано имя параметра, или строка - не комментарий, или символ комментария не задан, 
rem то строка "чисто" содержит искомый параметр и возвращаем - 1
if "!l_prms[%_j%]#Name!" EQU "" endlocal & exit /b 1
if "%_cfg_cmt%" EQU "" endlocal & exit /b 1
if "!l_ln_pname:~0,%_cmt_len%!" NEQ "%_cfg_cmt%" endlocal & exit /b 1

echo 15
rem иначе - требует дальнейшей проверки, возвращаем 2
endlocal & exit /b 2

rem ---------------------------------------------
rem Возвращает признак наличия закомментированного 
rem параметра ("имя"-"значение") в строке
rem ---------------------------------------------
:find_cmt_pval
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _j=%~3
set _cfg_cmt=%~4

echo 16
rem формируем и проверяем наличие параметра со значением
call :get_pval "%_pkg_name%" "%_mod_name%" %_j%
set pval=%pval:"=%
set pval=%pval: =%
echo 16.1 "%pval%"
rem получаем отдельно параметр и его значение из анализируемой строки конфигурационного файла и формируем "параметр"-"значение"
for /F "eol= tokens=1,2 delims=%_cfg_cmt%= " %%a in ("!l_ln!") do (set "l_pname=%%~a" & set "l_pval=%%~b")
echo 16.2
if "%l_pname%" EQU "" endlocal & exit /b 3
rem if "%l_pval%" EQU "" endlocal & exit /b 3

if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
	set l_ln_pval=%l_pname% %l_pval%
) else (
	set l_ln_pval=%l_pname%=%l_pval%
)
if "%l_ln_pval%" EQU "" endlocal & exit /b 3
echo 16.5 "%l_ln_pval%"
set l_ln_pval=%l_ln_pval:"=%
echo 17 "%l_ln_pval%" "%pval%"

rem если комментарий содержит параметр со значением, то возвращаем 1
if /i "%l_ln_pval%" EQU "%pval%" endlocal & exit /b 1

echo 18
rem иначе - требует дальнейшей проверки, возвращаем 0
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает признак наличия закомментированного 
rem параметра ("имя") в строке
rem ---------------------------------------------
:find_cmt_pname
setlocal
set _j=%~1
set _cfg_cmt=%~2

echo 19
rem получаем отдельно параметр из анализируемой строки конфигурационного файла
for /F "eol= tokens=1 delims=%_cfg_cmt%= " %%a in ("!l_ln!") do set "l_pname=%%~a"

if /i "%l_pname%" EQU "" endlocal & exit /b 3
echo 20 "%l_pname%" "!l_prms[%_j%]#Name!"
rem если комментарий содержит просто имя параметра, то возвращаем 1
if /i "%l_pname%" EQU "!l_prms[%_j%]#Name!" endlocal & exit /b 1
echo 21

rem иначе - завершаем проверку, возвращаем 0
endlocal & exit /b 0

rem ---------------------------------------------
rem Применяет заданный параметр к строке и 
rem записывает его в файл
rem ---------------------------------------------
:apply_prm
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _find=%~3
set _j=%~4
set _tmp_file=%~5

rem формируем строку "параметр"-"значение"
call :get_pval "%_pkg_name%" "%_mod_name%" %_j%
rem и пишем её
if /i "%_find%" EQU "#Name" echo %pval%>>"%_tmp_file%" & endlocal & exit /b 0
if "!l_prms[%_j%]#After!" NEQ "" (
	echo !l_ln!>>"%_tmp_file%"
	echo %pval%>>"%_tmp_file%"
) else "!l_prms[%_j%]#Before!" NEQ "" (
	echo %pval%>>"%_tmp_file%"
	echo !l_ln!>>"%_tmp_file%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает строку "параметр"-"значение"
rem ---------------------------------------------
:get_pval
setlocal
set _proc_name=%~0
set _pkg_name=%~1
set _mod_name=%~2
set _j=%~3

if defined l_prms[%_j%]#PrmVal endlocal & set "%_proc_name:~5%=!l_prms[%_j%]#PrmVal!" & exit /b 0

set l_val=!l_prms[%_j%]#Val!

rem убираем кавычки, связываем и возвращаем значение параметра
set "$quot_val=%l_val:"=%"
call :binding_var "%_pkg_name%" "%_mod_name%" "%$quot_val%" l_bind_val

rem если у значения не было кавычек, то используем без кавычек, иначе - ставим их
if /i "%$quot_val%" EQU "%l_val%" (
	set l_val=%l_bind_val%
) else (
	set l_val="%l_bind_val%"
)
if "!l_prms[%_j%]#Name!" EQU "" endlocal & set "%_proc_name:~5%=%l_val%" & exit /b 0

if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
	set l_pval=!l_prms[%_j%]#Name! %l_val%
) else (
	set l_pval=!l_prms[%_j%]#Name!=%l_val%
)
endlocal & set %_proc_name:~5%=%l_pval%
exit /b 0

rem ---------------------------------------------
rem Резервирует конфигурационные файлы модуля
rem ---------------------------------------------
:goal_backup_config
setlocal
set _mod_name=%~1
set _mod_ver=%~2

call :echo -ri:DefFuncNotImpl -v1:"%~0" & endlocal & exit /b 0

call :echo -ri:AddPathEnv -v1:%_dir% -rc:0F -ln:%VL_FALSE%
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Восстанавливает конфигурационные файлы модуля
rem из резервных копий
rem ---------------------------------------------
:goal_restore_config
setlocal
set _mod_name=%~1
set _mod_ver=%~2

call :echo -ri:DefFuncNotImpl -v1:"%~0" & endlocal & exit /b 0

call :echo -ri:AddPathEnv -v1:%_dir% -rc:0F -ln:%VL_FALSE%
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Связывает подстановочные переменные
rem https://www.robvanderwoude.com/battech_inputvalidation_setp.php
rem ---------------------------------------------
:binding_var
setlocal
set _proc_name=%~0
set _pkg_name=%~1
set _mod_name=%~2
set _var=%~3

rem echo 1. "%_var%"
if not defined _var endlocal & set "%4=" & exit /b 0
set $bind_var=%_var:${=%
rem если не нужно связывать переменную, то возвращаем её "как есть"
if /i "%$bind_var%" EQU "%_var%" endlocal & set "%4=%_var%" & exit /b 0

set l_vars=%_var%
:bind_vars_loop
for /f "tokens=1* delims=$}" %%i in ("!l_vars!") do (
	set l_var=%%i
	set $check_var=!l_var:~0,1!
	if /i "!$check_var!" EQU "{" (
		set l_var=!l_var:~1!
		call :convert_case %CM_LOWER% "!l_var!" l_lc_var
		rem echo "!_var!" "!l_var!" "!l_lc_var!"
		call :get_var_value !l_lc_var!
		rem echo var_value=!var_value!
		rem echo if defined var_value call :binding_var_value "!_var!" "!l_var!" "!var_value!" _var
		if defined var_value call :binding_var_value "!_var!" "!l_var!" "!var_value!" _var
	)
	set l_vars=%%j
)
if defined l_vars goto bind_vars_loop

rem echo 6. "%_var%"
set $bind_var=%_var:${=%
rem если не нужно связывать переменную, то возвращаем её "как есть"
if /i "%$bind_var%" EQU "%_var%" endlocal & set "%4=%_var%" & exit /b 0
rem иначе - пытаемся запросить у пользователя её значение
call :get_res_val -rf:"%menus_file%" -ri:InputBindVarsValues -v1:"%_var%"
call :choice_process "" "" %SHORT_DELAY% N "!res_val!"
if %choice% EQU %NO% call :echo -ri:InputBindVarsAbort -v1:"%_var%" & endlocal & exit /b 1

set l_vars=%_var%
:input_vars_loop
for /f "tokens=1* delims=$}" %%i in ("!l_vars!") do (
	set l_input_var=%%i
	set $check_input_var=!l_input_var:~0,1!
	if /i "!$check_input_var!" EQU "{" (
		set l_input_var=!l_input_var:~1!
		call :get_res_val -ri:InputBindVarValue -v1:!l_input_var!
		set /p l_input_val="!res_val!"
		set l_input_val=!l_input_val:"=!
		call :binding_var_value "%_var%" "!l_input_var!" "!l_input_val!" _var
	)
	set l_vars=%%j
)
if defined l_vars goto input_vars_loop
endlocal & set %4=%_var%
exit /b 0

rem ---------------------------------------------
rem Связывает подстановочные переменные с заданным
rem значениями
rem ---------------------------------------------
:binding_var_value _str _var _val
setlocal
set _str=%~1
set _var=%~2
set _val=%~3
rem echo binding_var_value: "%_str%" "%_var%" "%_val%"
set l_bind_str=!_str:${%_var%}=%_val%!
endlocal & set %4=%l_bind_str%
exit /b 0

rem ---------------------------------------------
rem Возвращает область видимости связываемой переменной
rem Возвращает: scope_pkg scope_mod
rem ---------------------------------------------
:get_var_scope _var_name
setlocal
set _svname=%~1

set $check_var_name=%_svname:.=%
if /i "%$check_var_name%" EQU "%_svname%" endlocal & (set "%2=%DEF_VAR_PKG%" & set "%3=") & exit /b 0
if /i "%_svname:~0,4%" EQU "pkg." endlocal & (set "%2=%g_pkg_name%" & set "%3=") & exit /b 0
if /i "%_svname:~0,4%" EQU "mod." endlocal & (set "%2=%g_pkg_name%" & set "%3=%g_mod_name%") & exit /b 0

set l_var_scopes=%_svname%
set vs=0
:var_scope_loop
for /f "tokens=1* delims=." %%i in ("!l_var_scopes!") do (
	set l_scopes[!vs!]=%%i
	set l_var_scopes=%%j
	set /a vs=!vs!+1
)
if defined l_var_scopes goto var_scope_loop

endlocal & (set "%2=%DEF_VAR_PKG%" & set "%3=")
exit /b 0

rem ---------------------------------------------
rem Устанавливает для подстановочных переменных
rem связываемые значения
rem ---------------------------------------------
:set_var_value _var_name _var_value
set _var_name=%~1
set _var_value=%~2
	echo 4

call :get_var_value %_var_name% scope_pkg scope_mod
if defined scope_mod (
	set l_curr_var_idx=!g_vars[%scope_pkg%][%scope_mod%]#Cnt!
) else (
	set l_curr_var_idx=!g_vars[%scope_pkg%]#Cnt!
)
echo "%_var_name%" "%scope_pkg%" "%scope_mod%"
echo 5
echo on
if defined scope_mod (
	if not defined l_curr_var_idx set l_curr_var_idx=-1
	if not defined var_value set /a "l_curr_var_idx+=1"
	set g_vars[%scope_pkg%][%scope_mod%][!l_curr_var_idx!]#Name=%_var_name%
	set g_vars[%scope_pkg%][%scope_mod%][!l_curr_var_idx!]#Val=%_var_value%
	set g_vars[%scope_pkg%][%scope_mod%]#Cnt=!l_curr_var_idx!
) else (
	if not defined l_curr_var_idx set l_curr_var_idx=-1
	if not defined var_value set /a "l_curr_var_idx+=1"
	set g_vars[%scope_pkg%][!l_curr_var_idx!]#Name=%_var_name%
	set g_vars[%scope_pkg%][!l_curr_var_idx!]#Val=%_var_value%
	set g_vars[%scope_pkg%]#Cnt=!l_curr_var_idx!
)
echo 6
echo off
exit /b 0

rem ---------------------------------------------
rem Возвращает для подстановочной переменной
rem связываемое значение
rem Возвращает: var_value scope_pkg scope_mod
rem ---------------------------------------------
:get_var_value _var_name
setlocal
set _proc_name=%~0
set _var_name=%~1

call :get_var_scope %_var_name% scope_pkg scope_mod

if defined scope_mod (
	for /l %%n in (0,1,!g_vars[%scope_pkg%][%scope_mod%]#Cnt!) do if /i "!g_vars[%scope_pkg%][%scope_mod%][%%n]#Name!" EQU "%_var_name%" (set "l_var_value=!g_vars[%scope_pkg%][%scope_mod%][%%n]#Val!" & goto end_get_var_value)
) else (
	for /l %%n in (0,1,!g_vars[%scope_pkg%]#Cnt!) do if /i "!g_vars[%scope_pkg%][%%n]#Name!" EQU "%_var_name%" (set "l_var_value=!g_vars[%scope_pkg%][%%n]#Val!" & goto end_get_var_value)
)
:end_get_var_value
if defined scope_mod (
	endlocal & (set "%_proc_name:~5%=%l_var_value%" & set "%2=%scope_pkg%" & set "%3=%scope_mod%")
) else (
	endlocal & (set "%_proc_name:~5%=%l_var_value%" & set "%2=%scope_pkg%")
)
exit /b 0

rem ---------------------------------------------
rem Выводит подстановочные переменные и их
rem связываемые значения для заданного пакета 
rem и/или модуля
rem ---------------------------------------------
:print_var_values
setlocal
set l_prev_idx=-1
for /f "usebackq delims=[]=# tokens=1-6" %%j in (`set g_vars`) do (
	rem echo "%%j" "%%k" "%%l" "%%m" "%%n" "%%o"
	set l_pkg=%%~k
	set l_val=%%~o
	if defined l_val (
		set l_mod=%%~l
		set l_idx=%%~m
		set l_var=%%~n
		set l_scope=[!l_pkg!][!l_mod!]:
	) else (
		set l_mod=
		set l_idx=%%~l
		set l_var=%%~m
		set l_val=%%~n
		set l_scope=[!l_pkg!]:
	)
	if /i "!l_idx!" EQU "Cnt" set l_cnt=!l_var!
	if !l_prev_idx! NEQ !l_idx! (
		if /i "!l_var!" EQU "Name" set l_var_name=!l_val!
	) else (
		if /i "!l_var!" EQU "Val" echo !l_scope! !l_var_name!=!l_val!
	)
	set l_prev_idx=!l_idx!
) 
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает в ERRORLEVEL код режима выполнения
rem ---------------------------------------------
:get_exec_code
setlocal
set _proc_name=%~0

if /i "%EXEC_MODE%" EQU "%EM_EML%" endlocal & set "%_proc_name:~5%=%CODE_EML%" & exit /b %CODE_EML%
if /i "%EXEC_MODE%" EQU "%EM_TST%" endlocal & set "%_proc_name:~5%=%CODE_TST%" & exit /b %CODE_TST%
if /i "%EXEC_MODE%" EQU "%EM_RUN%" endlocal & set "%_proc_name:~5%=%CODE_RUN%" & exit /b %CODE_RUN%
if /i "%EXEC_MODE%" EQU "%EM_DBG%" endlocal & set "%_proc_name:~5%=%CODE_DBG%" & exit /b %CODE_DBG%

endlocal & set %_proc_name:~5%=%EM_EML%
exit /b %EM_EML%

rem ---------------------------------------------
rem Устанавливает все необходимые параметры
rem и ресурсы для работы системы
rem ---------------------------------------------
:bis_setup
rem УСТАНОВКА И ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ:
rem определяем текущий каталог
for %%a in ("%CD%") do set "CUR_DIR=%%~fa"
rem символ пустого xml-узла
set EMPTY_NODE=~
rem возможные символы комментариев в конфигах модулей
set CMT_SYMBS=";:#"

rem Пакет по умолчанию для значений связываемых переменных
set DEF_VAR_PKG=VARS
rem Идентификаторы связываемых переменных:
set BV_BIS_DIR=bisdir
set BV_WIN_DIR=windir
set BV_PROG_FILES_DIR=env.programfiles
set BV_PKG_NAME=pkg.name
set BV_PKG_SETUP_DIR=pkg.setupdir
set BV_MOD_NAME=mod.name
set BV_MOD_VERSION=mod.version
set BV_MOD_SETUP_DIR=mod.setupdir
set BV_MOD_DISTR_DIR=mod.destribdir

rem Каталоги по умолчанию:
rem системные (не меняются)
set DEF_MOD_DIR=%CUR_DIR%%DIR_SEP%modules
set DEF_CFG_DIR=%CUR_DIR%%DIR_SEP%config
set DEF_RES_DIR=%CUR_DIR%%DIR_SEP%resources
set DEF_UTL_DIR=%CUR_DIR%%DIR_SEP%utils
rem пакетные (меняются в зависимости от настроек конкретного пакета)
set DEF_BAK_DAT_DIR=%CUR_DIR%%DIR_SEP%backup%DIR_SEP%data
set DEF_BAK_CFG_DIR=%CUR_DIR%%DIR_SEP%backup%DIR_SEP%config
set DEF_LOG_DIR=%CUR_DIR%%DIR_SEP%logs
set DEF_DISTRIB_DIR=%CUR_DIR%%DIR_SEP%distrib

rem определяем путь и праметры утилиты изменения цвета
call :chgcolor_setup "%DEF_UTL_DIR%%DIR_SEP%%PA_X86%"
if ERRORLEVEL 1 call :chgcolor_setup "%DEF_UTL_DIR%%DIR_SEP%%PA_X64%"

rem Фазы (регистр как в конфигурационном файле пакета)
set PH_DOWNLOAD=download
set PH_INSTALL=install
set PH_CONFIG=config
set PH_BACKUP=backup
set PH_UNINSTALL=uninstall

rem Цели
set GL_SILENT=SILENT
set GL_CMD_SHELL=CMD-SHELL
set GL_UNPACK_ZIP=UNPACK-ZIP
set GL_UNPACK_7Z_SFX=UNPACK-7Z-SFX
set GL_UNINSTALL_PORTABLE=UNINSTALL-PORTABLE

rem Определяем разрядность системы 
call :get_proc_arch
if not defined proc_arch set proc_arch=%PA_X86%

rem РАЗБОР ПАРАМЕТРОВ ЗАПУСКА:
set bis_param_defs="-ul,p_use_log;-ll,p_log_level,%LL_DEF%;-pa,proc_arch,%proc_arch%;-lc,locale;-ld,bis_log_dir,%DEF_LOG_DIR%;-dd,bis_distrib_dir,%DEF_DISTRIB_DIR%;-ud,bis_utils_dir,%DEF_UTL_DIR%;-bd,bis_backup_data_dir,%DEF_BAK_DAT_DIR%;-bc,bis_backup_config_dir,%DEF_BAK_CFG_DIR%;-md,bis_modules_dir,%DEF_MOD_DIR%;-cd,bis_config_dir,%DEF_CFG_DIR%;-rd,bis_res_dir,%DEF_RES_DIR%;-lf,p_license_file;-em,EXEC_MODE,#,%EM_RUN%;-pc,p_pkg_choice;-mc,p_mod_choice;-ec,p_exec_choice;-pn,p_pkg_name;-mn,p_mod_name"
call :parse_params %~0 %bis_param_defs% %*
rem ошибка разбора определений параметров
rem if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem вывод справки
if ERRORLEVEL 1 call :bis_help & endlocal & exit /b 0

rem вывод значений параметров запуска системы
if /i "%EXEC_MODE%" EQU "%EM_DBG%" set l_is_print_params=%VL_TRUE%
if /i "%EXEC_MODE%" EQU "%EM_TST%" set l_is_print_params=%VL_TRUE%
if defined p_log_level if %p_log_level% GTR %LL_INF% set l_is_print_params=%VL_TRUE%
if defined l_is_print_params call :print_params %~0

rem глобальный уровень логгирования
set g_log_level=%p_log_level%
rem лог-файл системы BIS
if /i "%p_use_log%" EQU "%VL_TRUE%" set g_log_file=%bis_log_dir%%DIR_SEP%BIS.log

rem Определяем локаль системы
if not defined locale call :get_locale 1>nul 2>&1

rem каталоги системы, зависящие от разрядности ОС
set bis_distrib_dir=%bis_distrib_dir%%DIR_SEP%windows%DIR_SEP%%proc_arch%
set bis_utils_dir=%bis_utils_dir%%DIR_SEP%%proc_arch%

rem файлы ресурсов
set g_res_file=%bis_res_dir%%DIR_SEP%strings_%locale%.txt
set menus_file=%bis_res_dir%%DIR_SEP%menus_%locale%.txt
set help_file=%bis_res_dir%%DIR_SEP%helps_%locale%.txt
set xpaths_file=%bis_res_dir%%DIR_SEP%xpaths.txt

call :echo -ri:LocaleInfo -v1:%locale%

rem выводим заголовок программы
call :echo -rv:"%g_script_header% " -rc:08 -ln:%VL_FALSE%
rem выводим информацию о режиме запуска и заданном при запуске уровне логгирования
call :echo -rv:"[" -rc:08 -ln:%VL_FALSE%
call :echo -rv:"MODE: %EXEC_MODE%" -rc:0F -ln:%VL_FALSE%
if defined p_use_log call :echo -rv:"; LOG_LEVEL: %p_log_level%" -rc:0F -ln:%VL_FALSE%
rem call :echo -rv:""
call :echo -rv:"]" -rc:08
rem если не найден файл лицензии
if not exist "%p_license_file%" call :echo -ri:ProgramLicenseMsg -rc:0F
call :echo -ri:InitSetupParams -ln:%VL_FALSE% -be:1
rem call :echo -ri:ProcArchDefError -be:1
call :echo -ri:ProcArchInfo -v1:%proc_arch%

rem утилиты
set z7_=%bis_utils_dir%%DIR_SEP%7-zip%DIR_SEP%7za.exe
set copy_=robocopy.exe
set xml_=%bis_utils_dir%%DIR_SEP%xml.exe
set xml_sel_=%bis_utils_dir%%DIR_SEP%xml.exe sel -T -t -m
set curl_=%bis_utils_dir%%DIR_SEP%curl%DIR_SEP%bin%DIR_SEP%curl.exe
set wget_=%bis_utils_dir%%DIR_SEP%wget%DIR_SEP%wget.exe

rem Формируем пути от начала текущего диска (http://www.rsdn.ru/forum/setup/2810022.hot)
for /f %%i in ("%bis_log_dir%") do set bis_log_dir=%%~dpnxi
for /f %%i in ("%bis_distrib_dir%") do set bis_distrib_dir=%%~dpnxi
for /f %%i in ("%bis_utils_dir%") do set bis_utils_dir=%%~dpnxi
for /f %%i in ("%bis_config_dir%") do set bis_config_dir=%%~dpnxi
for /f %%i in ("%bis_backup_data_dir%") do set bis_backup_data_dir=%%~dpnxi
for /f %%i in ("%bis_res_dir%") do set bis_res_dir=%%~dpnxi

call :echo -ri:ResultOk -rc:0A

exit /b 0

rem ---------------------------------------------
rem Проверяет установку всех необходимых параметров
rem и ресурсов системы
rem ---------------------------------------------
:bis_check_setup
setlocal
call :echo -ri:CheckSetupParams -ln:%VL_FALSE%
rem КОНТРОЛЬ:
rem наличия каталогов
if not exist "%bis_log_dir%" call :echo -ri:LogDirExistError -v1:"%bis_log_dir%" & endlocal & exit /b 1
if not exist "%bis_modules_dir%" call :echo -ri:ModulesDirExistError -v1:"%bis_modules_dir%" & endlocal & exit /b 1
if not exist "%bis_res_dir%" call :echo -ri:ResDirExistError -v1:"%bis_res_dir%" & endlocal & exit /b 1
rem наличия ресурсов
if not exist "%g_res_file%" call :echo -ri:ResFileExistError -v1:"%g_res_file%" & endlocal & exit /b 1
if not exist "%menus_file%" call :echo -ri:ResFileExistError -v1:"%menus_file%" & endlocal & exit /b 1
if not exist "%help_file%" call :echo -ri:ResFileExistError -v1:"%help_file%" & endlocal & exit /b 1
if not exist "%xpaths_file%" call :echo -ri:ResFileExistError -v1:"%xpaths_file%" & endlocal & exit /b 1
rem наличия утилит
if not exist "%z7_%" call :echo -ri:UtilExistError -v1:"%z7_%" & endlocal & exit /b 1
if not exist "%xml_%" call :echo -ri:UtilExistError -v1:"%xml_%" & endlocal & exit /b 1
if not exist "%curl_%" call :echo -ri:UtilExistError -v1:"%curl_%" & endlocal & exit /b 1
if not exist "%wget_%" call :echo -ri:UtilExistError -v1:"%wget_%" & endlocal & exit /b 1
rem наличия каталогов
if not exist "%bis_distrib_dir%" call :echo -ri:DistribDirExistError -v1:"%bis_distrib_dir%" & endlocal & exit /b 1
if not exist "%bis_utils_dir%" call :echo -ri:UtilsDirExistError -v1:"%bis_utils_dir%" & endlocal & exit /b 1
if not exist "%bis_config_dir%" call :echo -ri:ConfigDirExistError -v1:"%bis_config_dir%" & endlocal & exit /b 1
if not exist "%bis_backup_data_dir%" call :echo -ri:BackupDirExistError -v1:"%bis_backup_data_dir%" & endlocal & exit /b 1

call :echo -ri:ResultOk -rc:0A

call :echo -ri:LogDir -v1:"%bis_log_dir%"
call :echo -ri:DistribDir -v1:"%bis_distrib_dir%"
call :echo -ri:UtilsDir -v1:"%bis_utils_dir%"
call :echo -ri:ModulesDir -v1:"%bis_modules_dir%"
call :echo -ri:BackupDir -v1:"%bis_backup_data_dir%"
call :echo -ri:ConfigDir -v1:"%bis_config_dir%"
endlocal
rem связываем подстановочные переменные
call :set_var_value %BV_BIS_DIR% "%CUR_DIR%"
call :set_var_value %BV_WIN_DIR% "%windir%"
rem получаем каталог приложений ОС
set l_program_files=%programfiles(x86)%
if %proc_arch% EQU %PA_X64% (
	set l_program_files=%programfiles%
) else if not exist "%l_program_files%" set l_program_files=%programfiles%
call :set_var_value %BV_PROG_FILES_DIR% "%l_program_files%"
exit /b 0

rem ---------------------------------------------
rem Формат запуска установщика пакетов
rem ---------------------------------------------
:bis_help
echo.
endlocal & exit /b 1

rem ---------------- EOF bis.cmd ----------------
@Echo Off
rem {Copyright}
rem {License}
rem Сценарий получения и отображения ресурсов (строковых) заданным цветом и возможностью логгирования

setlocal EnableExtensions EnableDelayedExpansion

rem УСТАНОВКА И ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ:
set g_script_name=%~nx0

call :echo %*
if ERRORLEVEL 1 endlocal & exit /b 1

endlocal & exit /b 0

rem ---------------------------------------------
rem Получает и отображает ресурс (строковый)
rem ---------------------------------------------
:echo %*
setlocal
rem Устанавливаем все необходимые параметры и ресурсы для работы скрипта, и проверяем их корректность
call :echo_res_setup %*
call :echo_res_check_setup
if ERRORLEVEL 1 endlocal & exit /b 1

if defined p_cmd if /i "%p_cmd%" EQU "GET" call :get_res_val & echo !res_val! & endlocal & exit /b %ERRORLEVEL%
rem echo "%script_hdr%" "%res_path%" "%p_res_id%"

rem если передано значение ресурса
if defined res_val (
	if /i "%categ_name%" NEQ "" set res_val=%categ_name%: %res_val%
	call :set_res_color %res_color% 
	call :echo_level_res "%res_val%" "%ln%" "%log_lvl%" "%categ_num%"
) else if /i "%p_res_val_empty%" EQU "%VL_TRUE%" (
	call :echo_level_res "%res_val%" "%ln%" "%log_lvl%" "%categ_num%"
) else (
	rem иначе получаем ресурс по его ИД
	call :get_res_val
	rem echo !res_code! !res_categ! !categ_num! !categ_name! !res_val! "!result!"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

	rem если не только вывод в файл
	if /i "!categ_name!" NEQ "%CTG_FILE%" (
		rem определяем цвет символов и формат вывода по категории ресурса
		if /i "!categ_name!" EQU "%CTG_ERR%" (
			rem ресурс-ошибка
			set l_res_color=0C
			set res_val=!categ_name!-!res_code!: %p_res_id%: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_WRN%" (
			rem ресурс-предупреждение
			set l_res_color=0E
			set res_val=!categ_name!-!res_code!: %p_res_id%: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_INF%" (
			rem ресурс-информация
			set l_res_color=09
			set res_val=!categ_name!-!res_code!: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_FINE%" (
			rem ресурс-отладка
			set l_res_color=08
			set res_val=!categ_name!-!res_code!: !res_val!
		) else (
			set l_res_color=%res_color%
		)
		call :set_res_color !l_res_color!
		call :echo_level_res "!res_val!" "%ln%" "%log_lvl%" "!categ_num!"
	)
)
call :echo_log "%log_path%" "%res_val%" "%categ_num%" "%log_lvl%" "%script_hdr%"
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит ресурс в лог-файл
rem ---------------------------------------------
:echo_log _log_path _res_val _categ_num _log_lvl _script_hdr
setlocal
set _log_path=%~1
set _res_val=%~2
set _categ_num=%~3
set _log_lvl=%~4
set _script_hdr=%~5

rem если не указан лог файл, то завершаем сценарий
if "%_log_path%" EQU "" endlocal & exit /b 1

if not exist "%_log_path%" (
	echo %_script_hdr% > "%_log_path%"
	echo. >> "%_log_path%"
)
rem FOR /F "usebackq tokens=*" %%A IN (`%modules_dir%iso_date.cmd -df:DATE_TIME 2^>nul`) DO set iso_date_time=%%A
if "%_categ_num%" EQU "" set _categ_num=0
set l_res_val=%DATE% %TIME%: %_res_val%
rem для вывода круглых скобок echo должны быть на отдельных строках
if defined _log_lvl (
	if %_categ_num% LEQ %_log_lvl% echo %l_res_val% >> "%_log_path%"
) else (
	echo %l_res_val% >> "%_log_path%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает значение ресурса (строкового)
rem (устанавливает: 	g_res[%res_name%][%p_res_id%]#Val
rem						g_res[%res_name%][%p_res_id%]#Code
rem						g_res[%res_name%][%p_res_id%]#Categ
rem						g_res[%res_name%][%p_res_id%]#CategNum
rem						g_res[%res_name%][%p_res_id%]#CategName)
rem ---------------------------------------------
:get_res_val _proc_param...
set _proc_name=%~0
set _proc_param=%~1

rem если передан хотя бы один параметр, прогоняем их все через установку
if "%_proc_param%" NEQ "" call :echo_res_setup %*
for /f %%i in ("%res_path%") do set res_name=%%~ni
set g_res_output_cnt=

rem если ресурс был ранее определён, то используем его
if defined g_res[%res_name%][%p_res_id%]#Val (
	set res_code=!g_res[%res_name%][%p_res_id%]#Code!
	set res_categ=!g_res[%res_name%][%p_res_id%]#Categ!
	set categ_num=!g_res[%res_name%][%p_res_id%]#CategNum!
	set categ_name=!g_res[%res_name%][%p_res_id%]#CategName!
	set res_val=!g_res[%res_name%][%p_res_id%]#Val!
	goto res_found
) else (
	rem иначе выполняем поиск ресурса
	for /F "usebackq eol=; skip=1 tokens=1-4 delims=	" %%i in ("%res_path%") do (
		rem echo Из ресурсного файла "%res_path%": "%%i" "%%j" "%%k"  "%%l"
		set l_id=%%i
		set l_code=%%j
		set l_categ=%%k
		set l_val=%%l

		if /i "!l_id!" EQU "%p_res_id%" (
			set res_code=!l_code!
			if not defined res_categ (
				set res_categ=!l_categ!
				set categ_num=!l_categ:~0,1!
				set categ_name=!l_categ:~1!
			)
			set res_val=!l_val!
			set g_res[%res_name%][%p_res_id%]#Val=!l_val!
			set g_res[%res_name%][%p_res_id%]#Code=!l_code!
			set g_res[%res_name%][%p_res_id%]#Categ=!res_categ!
			set g_res[%res_name%][%p_res_id%]#CategNum=!categ_num!
			set g_res[%res_name%][%p_res_id%]#CategName=!categ_name!
			goto res_found
		)
	)
)
set l_err_msg=ERR -1: Не найден ресурс [ИД=%p_res_id%] в файле "%res_path%". Проверьте, пожалуйста, его наличие.
rem если не только вывод в файл
if /i "%categ_name%" NEQ "%CTG_FILE%" (
	rem ChangeColor 12 0
	%ChangeColor_12_0%
	1>nul chcp %code_page% & echo !l_err_msg!
) else (
	call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
)
exit /b 1

:res_found
rem если не определён цвет для переменных, то сразу подставляем переменные в строку
set is_color_defined=%VL_FALSE%
if defined p_val_color (set is_color_defined=%VL_TRUE%) else (for /l %%i in (1,1,%colors_cnt%) do if defined p_val_color_%%i set "is_color_defined=%VL_TRUE%" & goto :color_defined)

:color_defined
if /i "%is_color_defined%" NEQ "%VL_TRUE%" goto res_val_create

rem если определён цвет для переменных, то формируем последовательность вывода
call :create_res_output "%res_name%" "%p_res_id%" "%res_val%"
goto end_get_res_val

:res_val_create
rem подставляем значения переменных ресурса
for /l %%i in (1,1,%values_cnt%) do if defined p_val_%%i (call :res_bind_var "!res_val!" {%V_SYMB%%%i} p_val_%%i & set res_val=!bind_var!) else (goto end_get_res_val)

:end_get_res_val
set %_proc_name:~5%=!res_val!
exit /b 0

rem ---------------------------------------------
rem Подставляет значение переменной ресурса
rem ---------------------------------------------
:res_bind_var _res_val _var _val
setlocal
set _proc_name=%~0
set _res_val=%~1
set _var=%~2
set _val=!%3!

set _res_val=!_res_val:%_var%=%_val%!

endlocal & set %_proc_name:~5%=%_res_val%
exit /b 0

rem ---------------------------------------------
rem Создаёт последовательность вывода ресурса
rem (устанавливает: 	g_res_tpl[%_res_name%][%_res_id%][0]#Cnt
rem 					g_res_tpl[%_res_name%][%_res_id%][!er!]#Part
rem 					g_res_output_cnt
rem						g_res_output[%%j]#Part
rem 					g_res_output[%%j]#Color)
rem ---------------------------------------------
:create_res_output _res_name _res_id _res_val
set _res_name=%~1
set _res_id=%~2
set _res_val=%~3

rem если определён размер шаблона последовательности вывода, то переходим к её формированию
if defined g_res_tpl[%_res_name%][%_res_id%][0]#Cnt goto res_parts_loop

rem иначе - опредляем шаблон
set l_tmp_val=%_res_val%
set er=0
set l_vars_cnt=0
:res_output_loop
for /f "tokens=1* delims={}" %%a in ("%l_tmp_val%") do (
	set l_part=%%a
	rem echo "!l_part!"
	rem определяем подстановочная ли переменная и если да, то вычисляем их количество в строковом ресурсе
	if "!l_part:~0,1!" EQU "!V_SYMB!" (
		set l_var_num=!l_part:~1!
		set "l_check_var_num="&for /f "delims=0123456789" %%i in ("!l_var_num!") do set l_check_var_num=%%i
		if not defined l_check_var_num if !l_var_num! GEQ !l_vars_cnt! set l_vars_cnt=!l_var_num!
	)
	set g_res_tpl[%_res_name%][%_res_id%][!er!]#Part=!l_part!
	set l_tmp_val=%%b
 	set /a "er+=1"
)
if defined l_tmp_val goto :res_output_loop
set /a "g_res_tpl[%_res_name%][%_res_id%][0]#Cnt=%er%-1"

:res_parts_loop
set g_res_output_cnt=!g_res_tpl[%_res_name%][%_res_id%][0]#Cnt!

if %g_res_output_cnt% EQU 0 set "g_res_output_cnt=" & exit /b 0
rem echo "%g_res_output_cnt%"

for /l %%j in (0,1,%g_res_output_cnt%) do (
	set l_res_part=!g_res_tpl[%_res_name%][%_res_id%][%%j]#Part!

	set $check_part=!l_res_part!
	for /l %%i in (1,1,%l_vars_cnt%) do (
		if "!l_res_part!" EQU "!V_SYMB!%%i" (
			if defined p_val_%%i (
				set "$check_part=!p_val_%%i!" & set "l_part_color=!p_val_color_%%i!"
			) else (
				set "$check_part=" & set "l_part_color="
			)
		)
	)
	if not defined l_part_color set l_part_color=%p_val_color%
	rem если не подстановочная переменная, то устанавливаем цвет ресурса
	if "!$check_part!" EQU "!l_res_part!" (
		set g_res_output[%%j]#Part=!l_res_part!
		set g_res_output[%%j]#Color=%res_color%
	) else (
		set g_res_output[%%j]#Part=!$check_part!
		set g_res_output[%%j]#Color=!l_part_color!
	)
)
exit /b 0

rem ---------------------------------------------
rem Выводит ресурс в завиимости от режима выполнения
rem и уровня логгирования
rem (в тестовом режиме сообщения выводятся только
rem с признаком игнорирования тестового режима)
rem ---------------------------------------------
:echo_level_res _res_val _ln _log_lvl _categ_num
setlocal
set _res_val=%~1
set _ln=%~2
set _log_lvl=%~3
set _categ_num=%~4
rem если не в режиме тестирования или в нём, но задано игнорирование этого режима, то выводим ресурс
if /i "%EXEC_MODE%" NEQ "%EM_TST%" goto echo_res_any_case
if /i "%ignore_test_exec_mode%" NEQ "%VL_TRUE%" endlocal & exit /b 0
:echo_res_any_case
if "%_categ_num%" EQU "" set _categ_num=0
rem если задан уровень логгирования, то контролируем его
if "%_log_lvl%" NEQ "" (
	rem echo if %_categ_num% LEQ %_log_lvl% call :echo_res_val "%_res_val%" "%_ln%"
	if %_categ_num% LEQ %_log_lvl% call :echo_res_val "%_res_val%" "%_ln%"
) else (
	rem иначе просто выводим значение ресурса
	call :echo_res_val "%_res_val%" "%_ln%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит значение ресурса (строкового)
rem ---------------------------------------------
:echo_res_val _res_val _ln
setlocal
set _res_val=%~1
set _ln=%~2

rem выполняем заданное кол-во переводов строк до вывода значения ресурса
for /l %%i in (1,1,%before_echo_cnt%) do echo.
rem формируем заданное кол-во отступов вправо
for /l %%i in (1,1,%right_shift_cnt%) do set "l_spaces=!l_spaces! "
rem если определена последовательность вывода, то выводим значение ресурса согласно ей
if defined g_res_output_cnt (
	1>nul chcp %code_page%
	for /l %%j in (0,1,%g_res_output_cnt%) do (
		if defined g_res_output[%%j]#Part (
			call :set_res_color !g_res_output[%%j]#Color!
			set l_part=!g_res_output[%%j]#Part!
			call :get_end_space %%j
			rem для вывода круглых скобок echo должны быть на отдельных строках
			if %right_shift_cnt% EQU 0 (
				echo | set /p "dummyName=!l_part!"
			) else (
				if %%j EQU 0 (
					echo | set /p "dummyName=%BS%!l_spaces!!l_part!!end_space!"
				) else (
					echo | set /p "dummyName=!l_part!!end_space!"
				)
			)
		)
	)
	if /i "%_ln%" EQU "%VL_TRUE%" echo.
) else (
	rem  иначе - выводим значение ресурса
	if /i "%p_res_val_empty%" EQU "%VL_TRUE%" (
		rem если значение ресурса отсутствует
		if /i "%_ln%" EQU "%VL_TRUE%" echo.
	) else (
		1>nul chcp %code_page%
		rem  если определено значение ресурса, то учитываем отсутуп справа и перевод строки
		rem для вывода круглых скобок echo должны быть на отдельных строках
		if %right_shift_cnt% EQU 0 (
			if /i "%_ln%" EQU "%VL_TRUE%" (
				echo %_res_val%
			) else (
				echo | set /p "dummyName=%_res_val%"
			)
		) else (
			if /i "%_ln%" EQU "%VL_TRUE%" (
				echo !l_spaces!%_res_val%
			) else (
				echo | set /p "dummyName=%BS%!l_spaces!%_res_val%"
			)
		)
rem 1>&2 - для ошибки		
	)
)
rem выполняем заданное кол-во переводов строк после вывода значения ресурса
for /l %%i in (1,1,%after_echo_cnt%) do echo.
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает при необходимости заключительный пробел
rem ---------------------------------------------
:get_end_space _cur_idx
setlocal
set _proc_name=%~0
set _cur_idx=%~1

set /a l_next_id=%_cur_idx%+1
if not defined g_res_output[%l_next_id%]#Part endlocal & set "%_proc_name:~5%=" & exit /b 0

rem echo %l_next_id% "!g_res_output[%l_next_id%]#Part!"
if "!g_res_output[%l_next_id%]#Part:~0,1!" EQU " " set "l_space= "

endlocal & set %_proc_name:~5%=%l_space%
exit /b 0

rem ---------------------------------------------
rem Устанавливает заданный цвет символов выводимой строки
rem ---------------------------------------------
:set_res_color _color
setlocal
set _color=%~1

if /i "%_color%" EQU "" (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
) else if /i "%_color%" EQU "08" (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
) else if /i "%_color%" EQU "09" (
	rem ChangeColor 9 0
	%ChangeColor_9_0%
) else if /i "%_color%" EQU "0A" (
	rem ChangeColor 10 0
	%ChangeColor_10_0%
) else if /i "%_color%" EQU "0B" (
	rem ChangeColor 11 0
	%ChangeColor_11_0%
) else if /i "%_color%" EQU "0C" (
	rem ChangeColor 12 0
	%ChangeColor_12_0%
) else if /i "%_color%" EQU "0D" (
	rem ChangeColor 13 0
	%ChangeColor_13_0%
) else if /i "%_color%" EQU "0E" (
	rem ChangeColor 14 0
	%ChangeColor_14_0%
) else if /i "%_color%" EQU "0F" (
	rem ChangeColor 15 0
	%ChangeColor_15_0%
) else if /i "%_color%" EQU "AA" (
	rem ChangeColor 10 10
	%ChangeColor_10_10%
) else if /i "%_color%" EQU "CC" (
	rem ChangeColor 12 12
	%ChangeColor_12_12%
) else (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Определяет путь и праметры утилиты изменения цвета
rem ---------------------------------------------
:chgcolor_setup _chgcolor_dir
set _chgcolor_dir=%~1
if [%_chgcolor_dir:~-1%] EQU [%DIR_SEP%] set _chgcolor_dir=%_chgcolor_dir:~0,-1%
if not defined chgcolor_path (
	if exist "%b2eincfilepath%" (
		set chgcolor_path=%b2eincfilepath%chgcolor.exe
	) else (
		if not exist "%_chgcolor_dir%%DIR_SEP%chgcolor.exe" exit /b 1
		set chgcolor_path=%_chgcolor_dir%%DIR_SEP%chgcolor.exe
	)
	if defined chgcolor_path (
		set ChangeColor_8_0="!chgcolor_path!" 08
		set ChangeColor_9_0="!chgcolor_path!" 09
		set ChangeColor_10_0="!chgcolor_path!" 0A
		set ChangeColor_11_0="!chgcolor_path!" 0B
		set ChangeColor_12_0="!chgcolor_path!" 0C
		set ChangeColor_13_0="!chgcolor_path!" 0D
		set ChangeColor_14_0="!chgcolor_path!" 0E
		set ChangeColor_15_0="!chgcolor_path!" 0F
		set ChangeColor_10_10="!chgcolor_path!" AA
		set ChangeColor_12_12="!chgcolor_path!" CC
	)
)
exit /b 0

rem ---------------------------------------------
rem Устанавливает все необходимые параметры
rem и ресурсы для работы скрипта
rem ---------------------------------------------
:echo_res_setup %*
rem УСТАНОВКА И ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ:
rem цвет выводимого ресурса
set DEF_RES_COLOR=08
rem Категории ресурсов:
rem вывод значения ресурса только в файл
set CTG_FILE=FILE
rem вывод значения ресурса на экран/в файл
set CTG_CON=CON
rem ресурс-ошибка
set CTG_ERR=ERR
rem ресурс-предупреждение
set CTG_WRN=WRN
rem ресурс-информация
set CTG_INF=INF
rem ресурс-отладка
set CTG_FINE=FINE

rem идентификаторы подстановочных переменных
set V_SYMB=V

rem СБРОС ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ:
set res_val=
set res_categ=
set categ_num=
set categ_name=

rem РАЗБОР ПАРАМЕТРОВ ЗАПУСКА:
set echo_res_param_defs="-sh,script_hdr,%g_script_header%;-cm,p_cmd;-rf,res_path,%g_res_file%;-ri,p_res_id;-rv,res_val,~,p_res_val_empty;-rc,res_color,%DEF_RES_COLOR%;-rl,res_categ;-v,p_val_,~,~,values_cnt;-vc,p_val_color;-c,p_val_color_,~,~,colors_cnt;-ln,ln,%VL_TRUE%;-rs,right_shift_cnt,0;-be,before_echo_cnt,0;-ae,after_echo_cnt,0;-lf,log_path,%g_log_file%;-ll,log_lvl,%g_log_level%;-it,ignore_test_exec_mode,%VL_FALSE%;-cp,code_page,1251"
call :parse_params %~0 %echo_res_param_defs% %*
rem ошибка разбора определений параметров
rem if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem вывод справки
if ERRORLEVEL 1 call :echo_res_help & endlocal & exit /b 0
if /i "%EXEC_MODE%" EQU "%EM_DBG%" call :print_params %~0

rem При отсутствии заданных значений, устанавливаем по умолчанию
if not defined log_lvl set log_lvl=%LL_DEF%
rem определяем номер категории ресурса
if defined res_categ (
	set categ_num=%res_categ:~0,1%
	set categ_name=%res_categ:~1%
)
rem определяем путь и праметры утилиты изменения цвета
call :chgcolor_setup "%CUR_DIR%"
exit /b 0

rem ---------------------------------------------
rem Проверяет установку всех необходимых параметров
rem и ресурсов скрипта
rem ---------------------------------------------
:echo_res_check_setup
setlocal
rem КОНТРОЛЬ:
rem отсутствие ИД ресурса или файла ресурсов
if not defined p_res_id if not defined res_val if /i "%p_res_val_empty%" NEQ "%VL_TRUE%" (
	set l_err_msg=ERR -1: Не задано ни ИД ресурса, ни его значение. Укажите, пожалуйста, корректный ИД ресурса или его значение.
	rem если не только вывод в файл
	if /i "%categ_name%" NEQ "%CTG_FILE%" (
		rem ChangeColor 12 0
		%ChangeColor_12_0%
		1>nul chcp %code_page% & echo !l_err_msg!
		call :echo_res_help
	) else (
		call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
	)
	endlocal & exit /b 1
)
if defined p_res_id if not exist "%res_path%" (
	set l_err_msg=ERR -1: Для ресурса [ИД=%p_res_id%] не найден ресурсный файл "%res_path%". Проверьте, пожалуйста, его наличие.
	rem если не только вывод в файл
	if /i "%categ_name%" NEQ "%CTG_FILE%" (
		rem ChangeColor 12 0
		%ChangeColor_12_0%
		1>nul chcp %code_page% & echo !l_err_msg!
		call :echo_res_help
	) else (
		call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
	)
	endlocal & exit /b 1
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Формат запуска утилиты
rem ---------------------------------------------
:echo_res_help
setlocal
1>nul chcp %code_page%
echo.
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo Victory BIS: Resource module for Windows 7/10 v.{Current_Version}. {Copyright} {Current_Date}
rem ChangeColor 8 0 
%ChangeColor_8_0%
echo Формат запуска утилиты:
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo %g_script_name% [^<ключи^>...]
echo.
rem ChangeColor 8 0
%ChangeColor_8_0%
echo Ключи:
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -sh"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :заголовок логгируемой программы (не обязательно). Можно в вызывающем сценарии определить переменную g_script_header
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:путь к файлу ресурсов (не обязательно, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=если в вызывающем сценарии определить переменную g_res_file"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ri"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:идентификатор ресурса (не обязательно, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=если указан ключ -rv"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rv"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:значение ресурса (не обязательно, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=если указан ключ -ri"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rc"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :цвет символов выводимого ресурса (не обязательно). Задаётся в шестнадцатиричной системе [08, 09, 0A, 0B, 0C, 0D, 0E, 0F]
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rl"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :уровень логгирования ресурса (не обязательно). Возможны следуюшие значения [0FILE - вывод значения ресурса только в файл, 1CON - вывод значения ресурса на экран/в файл, 2ERR - ресурс-ошибка, 3WRN - ресурс-предупреждение, 4INF - ресурс-информация, 5FINE - ресурс-отладка]
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v1"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 1 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v2"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 2 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v3"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 3 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v4"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 4 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -lf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :путь к файлу лога (не обязательно). Можно в вызывающем сценарии определить переменную g_log_file
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ll"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:уровень логгирования (по умолчанию "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%LL_DEF%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo ). Можно в вызывающем сценарии определить переменную g_log_level [0 - сообщения в файл, 1 - сообщения на экран, 2 - ошибки, 3 - предупреждения, 4 - информация, 5 - отладка]
echo.
endlocal & exit /b 0
rem ---------------- EOF echo.cmd ----------------
rem {Copyright}
rem {License}
rem Сценарий работы с параметрами процедур и других сценариев

rem ---------------------------------------------
rem Разбирает и устанавливает значения переданным 
rem параметрам в заданной области видимости
rem ---------------------------------------------
:parse_params _scope _prm_defs %*
set _prm_scope=%~1
set _prm_defs=%~2

call :get_prm_scope "%_prm_scope%"

rem РАЗБОР ОПРЕДЕЛЕНИЙ ПАРАМЕТРОВ:
rem если ранее определения параметров были разобраны переходим к сбросу параметров и формированию значений
if defined g_prms[%prm_scope%]#Count goto end_param_defs
set l_prm_defs=%_prm_defs%
set "prm=0"
:param_defs_loop
for /f "tokens=1* delims=;" %%i in ("%l_prm_defs%") do (
	rem echo param definition: "%%i"
	set l_prm_def=%%i
	for /f "tokens=1-5 delims=," %%a in ("!l_prm_def!") do (
		rem echo param definition parts: "%%a" "%%b" "%%c" "%%d" "%%e"
		set l_key=%%~a
		if not defined l_key set "p_def_prm_err=%VL_TRUE%" & exit /b 2
		set l_name=%%~b
		if not defined l_name set "p_def_prm_err=%VL_TRUE%" & exit /b 2
		set l_def_val=%%~c
		set l_empty_var=%%~d
		set l_empty_val=%%~d
		set l_count_var=%%~e
		set g_prms[%prm_scope%][!prm!]#Key=!l_key!
		set g_prms[%prm_scope%][!prm!]#Name=!l_name!
		set g_prms[%prm_scope%][!prm!]#DefValue=
		set g_prms[%prm_scope%][!prm!]#EmptyVar=
		set g_prms[%prm_scope%][!prm!]#EmptyVal=
		set g_prms[%prm_scope%][!prm!]#CountVar=
		if defined l_def_val (
			rem если указано значение по умолчанию только в случае отсутствия параметра
			if "!l_def_val!" EQU "#" (
				rem echo not defined: "%%a" "%%b" "%%c" "%%d" "%%e"
				if defined l_empty_val if "!l_empty_val!" NEQ "~" set g_prms[%prm_scope%][!prm!]#EmptyVal=!l_empty_val!
			) else (
				if "!l_def_val!" NEQ "~" set g_prms[%prm_scope%][!prm!]#DefValue=!l_def_val!
				if defined l_empty_var (
					if "!l_empty_var!" NEQ "~" set g_prms[%prm_scope%][!prm!]#EmptyVar=!l_empty_var!
					if defined l_count_var if "!l_count_var!" NEQ "~" set g_prms[%prm_scope%][!prm!]#CountVar=!l_count_var!
				)
			)
		)
		set g_prms[%prm_scope%][!prm!]#Count=1
		set /a "prm+=1"
	)
	set l_prm_defs=%%j
)
if defined l_prm_defs goto :param_defs_loop
set /a "g_prms[%prm_scope%]#Count=%prm%-1"

:end_param_defs
rem СБРОС ПАРАМЕТРОВ:
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem echo reset: "!g_prms[%prm_scope%][%%n]#Key!" "!g_prms[%prm_scope%][%%n]#Name!" "!g_prms[%prm_scope%][%%n]#DefValue!"
	if defined !g_prms[%prm_scope%][%%n]#CountVar! (
		for /l %%i in (1,1,!g_prms[%prm_scope%][%%n]#Count!) do (
			set !g_prms[%prm_scope%][%%n]#Name!%%i=
			set g_prms[%prm_scope%][%%n]#Value%%i=
		)
		set !g_prms[%prm_scope%][%%n]#CountVar!=
		set g_prms[%prm_scope%][%%n]#Count=1
	) else if defined !g_prms[%prm_scope%][%%n]#Name! (
		rem если параметр определён,
		if not defined g_prms[%prm_scope%][%%n]#EmptyVal (
			rem то сбрасываем его только если не задано значение для не определённого параметра
			rem echo reset if not empty value: "!g_prms[%prm_scope%][%%n]#Name!"
			set !g_prms[%prm_scope%][%%n]#Name!=
			set g_prms[%prm_scope%][%%n]#Value=
		)
	)
)
rem УСТАНОВКА ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ: без контроля определения параметров
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem если указано значение по умолчанию
	if defined g_prms[%prm_scope%][%%n]#DefValue (
		rem echo set default value: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#DefValue!
		set !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#DefValue!
		set g_prms[%prm_scope%][%%n]#Value=!g_prms[%prm_scope%][%%n]#DefValue!
	)
)
rem ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПАРАМЕТРОВ:
rem переходим к аргументам-значениям параметров
shift
shift
:start_params_parse
set p_prm=%~1
set p_key=%p_prm:~0,3%
set p_val=%p_prm:~4%
set p_val=%p_val:"=%

if [%p_prm%] EQU [] goto end_params_parse

rem разбор параметров вывода справки
if [%p_prm%] EQU [/?] set "p_key_help=%VL_TRUE%" & exit /b 1
if /i [%p_prm%] EQU [--help] set "p_key_help=%VL_TRUE%" & exit /b 1

rem echo params key=value: %p_key%=%p_val%
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem разбор перечисляемых параметров
	if "!g_prms[%prm_scope%][%%n]#Key:~0,2!" EQU "!g_prms[%prm_scope%][%%n]#Key:~0,3!" (
		if "!g_prms[%prm_scope%][%%n]#CountVar!" NEQ "" (
			rem если полное совпадение ключа
			rem echo if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!!g_prms[%prm_scope%][%%n]#Count!" 
			if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!!g_prms[%prm_scope%][%%n]#Count!" (
				set !g_prms[%prm_scope%][%%n]#Name!!g_prms[%prm_scope%][%%n]#Count!=%p_val%
				set g_prms[%prm_scope%][%%n]#Value!g_prms[%prm_scope%][%%n]#Count!=%p_val%
				set !g_prms[%prm_scope%][%%n]#CountVar!=!g_prms[%prm_scope%][%%n]#Count!
				set /a "g_prms[%prm_scope%][%%n]#Count+=1"
			) else (
				rem проверка неполного совпадения ключа
				set half_key=%p_key:~0,2%
				set key_num=%p_key:~2%
				if /i "!half_key!" EQU "!g_prms[%prm_scope%][%%n]#Key!" (
					set "l_check_key_num="&for /f "delims=0123456789" %%i in ("!key_num!") do set l_check_key_num=%%i
					if not defined l_check_key_num (
						if !key_num! GTR !g_prms[%prm_scope%][%%n]#Count! (
							set g_prms[%prm_scope%][%%n]#Count=!key_num!
							set !g_prms[%prm_scope%][%%n]#Name!!g_prms[%prm_scope%][%%n]#Count!=%p_val%
							set g_prms[%prm_scope%][%%n]#Value!g_prms[%prm_scope%][%%n]#Count!=%p_val%
							set !g_prms[%prm_scope%][%%n]#CountVar!=!g_prms[%prm_scope%][%%n]#Count!
							set /a "g_prms[%prm_scope%][%%n]#Count+=1"
						)	
					)
				)
			)
		)
	) else if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!" (
		rem разбор одиночных параметров
		if defined p_val (
			rem если указано значение для не определённого параметра
			if defined g_prms[%prm_scope%][%%n]#EmptyVal (
				rem то устанавливаем заднное значение, только если он не определён
				if not defined !g_prms[%prm_scope%][%%n]#Name! (
					rem echo undefined param set value: !g_prms[%prm_scope%][%%n]#Name!=%p_val%
					set !g_prms[%prm_scope%][%%n]#Name!=%p_val%
					set g_prms[%prm_scope%][%%n]#Value=%p_val%
				)
			) else (
				set !g_prms[%prm_scope%][%%n]#Name!=%p_val%
				set g_prms[%prm_scope%][%%n]#Value=%p_val%
			)
		) else (
			rem установка признака пустого значения
			if "!g_prms[%prm_scope%][%%n]#EmptyVar!" NEQ "" set !g_prms[%prm_scope%][%%n]#EmptyVar!=true
		)
	)
)
shift
goto start_params_parse
:end_params_parse
rem УСТАНОВКА ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ: с контролем определения параметров
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem устанавливаем значение только, если задано значение для не определённого параметра и он не определён
	if defined g_prms[%prm_scope%][%%n]#EmptyVal if not defined !g_prms[%prm_scope%][%%n]#Name! (
		rem echo set empty value: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#EmptyVal!
		set !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#EmptyVal!
		set g_prms[%prm_scope%][%%n]#Value=!g_prms[%prm_scope%][%%n]#EmptyVal!
	)
)
exit /b 0

rem ---------------------------------------------
rem Печатает параметры и их значения, в т.ч.
rem значения по умолчанию
rem ---------------------------------------------
:print_params _scope
setlocal
set _prm_scope=%~1
call :get_prm_scope "%_prm_scope%"

for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	set l_start_symb=
	set l_end_bracket=
	if "!g_prms[%prm_scope%][%%n]#CountVar!" NEQ "" (
		for /l %%k in (1,1,!g_prms[%prm_scope%][%%n]#Count!) do (
			if defined !g_prms[%prm_scope%][%%n]#Name!%%k echo %prm_scope%: !g_prms[%prm_scope%][%%n]#Name!%%k=!g_prms[%prm_scope%][%%n]#Value%%k!
		)
	) else if defined !g_prms[%prm_scope%][%%n]#Name! (
				rem для вывода круглых скобок echo должны быть на отдельных строках
				echo | set /p "dummyName=%prm_scope%: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#Value! "
				set l_start_symb=^(
				if defined g_prms[%prm_scope%][%%n]#DefValue (
					echo | set /p "dummyName=!l_start_symb!!g_prms[%prm_scope%][%%n]#DefValue!"
					set "l_start_symb=,"
					set l_end_bracket=^)
				) else if defined g_prms[%prm_scope%][%%n]#EmptyVal (
					echo | set /p "dummyName=!l_start_symb!#!g_prms[%prm_scope%][%%n]#EmptyVal!"
					set "l_start_symb=,"
					set l_end_bracket=^)
				)
				if defined g_prms[%prm_scope%][%%n]#EmptyVar (
					echo | set /p "dummyName=!l_start_symb!!g_prms[%prm_scope%][%%n]#EmptyVar!"
					set l_end_bracket=^)
				)
				if defined l_end_bracket (
					echo !l_end_bracket!
				) else (
					echo.
				)
			)
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает нормированный идентификатор области 
rem видимости параметров
rem ---------------------------------------------
:get_prm_scope _scope
setlocal
set _proc_name=%~0
set _prm_scope=%~1
rem если область видимости процедура
if "%_prm_scope:~0,1%" EQU ":" (
	set l_prm_scope=%_prm_scope:~1%
) else if exist "%_prm_scope%" (
	rem если область видимости сценарий
	for /f %%i in ("%_prm_scope%") do set l_prm_scope=%%~ni
)
endlocal & set %_proc_name:~5%=%l_prm_scope%
exit /b 0
rem ---------------- EOF params.cmd ----------------
@Echo Off
rem {Copyright}
rem {License}
rem Сценарий работы с параметрами реестра
rem (доступ к переменным окружения)

rem ---------------------------------------------
rem Обеспечивает работу с параметрами реестра
rem ---------------------------------------------
:reg %*
setlocal
set _proc_name=%~0
rem Устанавливаем все необходимые параметры и ресурсы для работы скрипта, и проверяем их корректность
call :reg_setup %*
call :reg_check_setup
if ERRORLEVEL 1 endlocal & exit /b 1

rem получение значения параметра реестра
if /i "%oper_code%" NEQ "%RC_GET%" goto reg_not_get_cmd

call :get_reg_value "%oper_code%" "%key_name%" "%value_name%" 
if "%reg_value%" EQU "" call :echo -ri:RegQueryError -v1:"%value_name%" -rl:5FILE & endlocal & exit /b 1
call :echo -ri:RegGet -v1:"%key_name%" -v2:"%value_name%" -v3:"%reg_value%" -rl:5FILE

endlocal & set "%_proc_name:~1%=%reg_value%"
exit /b 0

:reg_not_get_cmd
rem установка значения параметра реестра
if /i "%oper_code%" EQU "%RC_SET%" (
	call :get_reg_value "%oper_code%" "%key_name%" "%value_name%" 
	if /i "!reg_value!" NEQ "%value_value%" (
		rem разбор куста
		if /i "%key_name%" EQU "%RH_HKLM%" (
			1>nul setx.exe %value_name% "%value_value%" /M
		) else (
			1>nul setx.exe %value_name% "%value_value%"
		)
		call :echo -ri:RegSet -v1:"%key_name%" -v2:"%value_name%" -v3:"%value_value%" -rl:5FILE
	)
	endlocal & exit /b 0
)
rem добавление значения параметра реестра
if /i "%oper_code%" EQU "%RC_ADD%" (
	call :get_reg_value "%oper_code%" "%key_name%" "%value_name%" 
	set $check_value=!reg_value:%value_value%=!
	if /i "!$check_value!" EQU "!reg_value!" (
		if "!reg_value:~-1!"==";" set reg_value=!reg_value:~0,-1!
		rem разбор куста
		if /i "%key_name%" EQU "%RH_HKLM%" (
			1>nul setx.exe %value_name% "!reg_value!;%value_value%" /M
		) else (
			1>nul setx.exe %value_name% "!reg_value!;%value_value%"
		)
		call :echo -ri:RegAdd -v1:"%key_name%" -v2:"%value_name%" -v3:"%value_value%" -v4:"!reg_value!;%value_value%" -rl:5FILE
	)
	endlocal & exit /b 0
)
rem удаление параметра реестра или его значения
if /i "%oper_code%" EQU "%RC_DEL%" (
	rem Если удаляемое значение задано
	if "%value_value%" NEQ "" (
		call :get_reg_value "%oper_code%" "%key_name%" "%value_name%" 
		set new_value=!reg_value:;%value_value%=!
		set new_value=!new_value:%value_value%;=!
		set new_value=!new_value:%value_value%=!
		if /i "!new_value!" NEQ "!reg_value!" (
			rem разбор куста
			if /i "%key_name%" EQU "%RH_HKLM%" (
				1>nul setx.exe %value_name% "!new_value!" /M
			) else (
				1>nul setx.exe %value_name% "!new_value!"
			)
		)
		call :echo -ri:RegDelVal -v1:"%key_name%" -v2:"%value_name%" -v3:"%value_value%" -v4:"!new_value!" -rl:5FILE
	) else (
		rem разбор куста
		if /i "%key_name%" EQU "%RH_HKLM%" (
			1>nul REG delete %HKLM% /F /V %value_name%
		) else (
			1>nul REG delete %HKCU% /F /V %value_name%
		)
		call :echo -ri:RegDel -v1:"%key_name%" -v2:"%value_name%" -rl:5FILE
	)
	endlocal & exit /b 0
)

call :echo -ri:RegOperUndefError -v1:"%oper_code%"
endlocal & exit /b 1

rem ---------------------------------------------
rem Возвращает значение заданной переменной реестра
rem ---------------------------------------------
:get_reg_value
setlocal
set _proc_name=%~0
set _oper_code=%~1
set _key_name=%~2
set _value_name=%~3

call :reg_setup_globals
rem Если задан куст HKLM, то читаем из него
if /i "%_key_name%" EQU "%RH_HKLM%" (
	FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %HKLM% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
) else if /i "%_key_name%" EQU "%RH_HKCU%" (
	rem Получаем значение переменной окружения (сначала из куста HKCU)
	FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %HKCU% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
	rem Если не получилось, то
	if "!l_value!" EQU "" (
		rem только в случае получения значения переменной окружения, пробуем получить из ветки HKLM 
		if /i "%_oper_code%" EQU "%RC_GET%" (
			FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %HKLM% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
		)
	)
) else (
	rem если не HKLM и не HKCU
	FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %_key_name% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
)
endlocal & set %_proc_name:~5%=%l_value%
exit /b 0

rem ---------------------------------------------
rem Устанавливает все необходимые глобальные переменные
rem ---------------------------------------------
:reg_setup_globals
rem ветки переменных окружения
set HKLM="HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
set HKCU="HKCU\Environment"
exit /b 0

rem ---------------------------------------------
rem Устанавливает все необходимые параметры
rem и ресурсы для работы скрипта
rem ---------------------------------------------
:reg_setup %*
call :reg_setup_globals

rem РАЗБОР ПАРАМЕТРОВ ЗАПУСКА:
rem если не указан куст, задаём ветку переменных окружения пользователя
set reg_param_defs="-oc,oper_code;-vn,value_name;-vv,value_value;-kn,key_name,%RH_HKCU%"
call :parse_params %~0 %reg_param_defs% %*
rem ошибка разбора определений параметров
if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem вывод справки
if ERRORLEVEL 1 call :reg_help & endlocal & exit /b 0
rem call :print_params %~0
exit /b 0

rem ---------------------------------------------
rem Проверяет установку всех необходимых параметров
rem и ресурсов скрипта
rem ---------------------------------------------
:reg_check_setup
setlocal
rem КОНТРОЛЬ:
rem отсутствие операции с параметром реестра
if "%oper_code%" EQU "" call :echo -ri:RegOperParamError -v1:"%value_name%" & call :reg_help & endlocal & exit /b 1

rem отсутствие имени параметра реестра
if "%value_name%" EQU "" call :reg_help & endlocal & exit /b 1
endlocal & exit /b 0

rem ---------------------------------------------
rem Формат запуска утилиты
rem ---------------------------------------------
:reg_help
echo. 1>&2
echo Victory BIS. Registry edit module for Windows 7 v.{Current_Version}. {Copyright}  {Current_Date} 1>&2
echo Формат запуска утилиты: 1>&2
echo %~nx0 [^<ключи^>...] 1>&2
echo Ключи: 1>&2
echo 	-oc:код_операции (^<help-помощь^|get-получить^|set-установить^|add-добавить^|del-удалить^>) 1>&2
echo 	-vn:имя_переменной_окружения 1>&2
echo 	-vv:значение_переменной_окружения (обязательно для операций set, add; опционально для del) 1>&2
echo 	-kn:куст [HKLM-на системном уровне^|HKCU-на уровне пользователя] (по умолчанию используется HKCU) 1>&2
exit /b 0
rem ---------------- EOF registry.cmd ----------------
rem {Copyright}
rem {License}
rem Сценарий работы с параметрами процедур и других сценариев

rem ---------------------------------------------
rem Удаляет ведущие и конечные пробелы
rem ---------------------------------------------
:trim
SET %2=%1
GOTO :EOF

rem ---------------------------------------------
rem Конвертирует слеши в обратные слеши и наоборот
rem согдасно заданному направлению (win|nix)
rem необходимо для некоторых windows-команд
rem ---------------------------------------------
:convert_slashes
setlocal
set _direction=%~1
set _var=%~2

if /i "%_direction%" EQU "%CSD_WIN%" (
	set _var=!_var:/=\!
) else (
	if /i "%_direction%" EQU "%CSD_NIX%" set _var=!_var:\=/!
)
endlocal & set "%3=%_var%"
exit /b 0

rem ---------------------------------------------
rem Возвращает длину строки
rem ---------------------------------------------
:len
setlocal enabledelayedexpansion&set l=0&set str=%~1
:len_loop
set x=!str:~%l%,1!&if not defined x (endlocal&set "%~2=%l%"&exit /b 0)
set /a l+=1&goto :len_loop

rem ---------------------------------------------
rem Конвертирует регистр (верхний/нижний) символов 
rem строки
rem ---------------------------------------------
:convert_case _case_mark _src_str conv_str
setlocal
Set _case_mark=%~1
Set _src_str=%~2

if /i "%_case_mark%" EQU "%CM_UPPER%" (
	CALL :UCase "%_src_str%"
	call :echo -ri:CaseConvert -v1:"%_src_str%" -v2:"%_case_mark%" -v3:"!UCase!"
	set l_conv_str=!UCase!
) else if /i "%_case_mark%" EQU "%CM_LOWER%" (
	CALL :LCase "%_src_str%"
	call :echo -ri:CaseConvert -v1:"%_src_str%" -v2:"%_case_mark%" -v3:"!LCase!"
	set l_conv_str=!LCase!
) else (
	call :echo -ri:CaseMarkUndefError
	rem call :exec_format & endlocal & exit /b 1
)
endlocal & set "%3=%l_conv_str%"
exit /b 0

rem ---------------------------------------------
rem Конвертирует регистр первого символа слова
rem в прописной
rem ---------------------------------------------
:capital_case _src_str conv_str
setlocal
Set _src_str=%~1

endlocal & set "%2=%l_conv_str%"
exit /b 0

rem ==========================================================================
rem Функции LCase() и UCase()
rem http://www.robvanderwoude.com/battech_convertcase.php
rem ==========================================================================
:LCase
:UCase
:: Converts to upper/lower case variable contents
:: Syntax: CALL :UCase _VAR1 _VAR2
:: Syntax: CALL :LCase _VAR1 _VAR2
:: _VAR1 = Variable NAME whose VALUE is to be converted to upper/lower case
:: _VAR2 = NAME of variable to hold the converted value
:: Note: Use variable NAMES in the CALL, not values (pass "by reference")
    setlocal enableextensions enabledelayedexpansion

	SET _UCase=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я
	SET _LCase=a b c d e f g h i j k l m n o p q r s t u v w x y z а б в г д е ё ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я
	SET _Lib_UCase_Tmp=%~1
	IF /I "%~0"==":UCase" SET _Abet=%_UCase%
	IF /I "%~0"==":LCase" SET _Abet=%_LCase%
	FOR %%Z IN (%_Abet%) DO SET _Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!
	set sProcName=%~0
    	endlocal & set %sProcName:~1%=%_Lib_UCase_Tmp%
	rem SET %2=%_Lib_UCase_Tmp%
exit /b 0

rem ---------------- EOF strings.cmd ----------------
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

rem ---------------------------------------------
rem Выводит наименование неявной цели выполнения
rem ---------------------------------------------
:print_exec_name
setlocal
set _proc_name=%~1

call :get_exec_name %_proc_name%
set $exec=%_proc_name:goal=%
if /i "%$exec%" NEQ "%_proc_name%" (
	call :echo -ri:ExecGoal -v1:"%exec_name%" -ae:1
) else (
	call :echo -ri:ExecPhaseId -v1:"%exec_name%" -ae:1
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает наименование этапа выполнения фазы/цели
rem (по наименованию процедуры)
rem ---------------------------------------------
:get_exec_name
setlocal
set _exec_name=%~0
set _proc_name=%~1

set $exec=%_proc_name:goal=%
if /i "%$exec%" NEQ "%_proc_name%" (
	set l_exec_name=%_proc_name:~6%
) else (
	set $exec=%_proc_name:phase=%
	if /i "!$exec!" NEQ "%_proc_name%" (
		set l_exec_name=%_proc_name:~7%
	) else (
		set l_exec_name=%_proc_name:~5%
	)
)
set l_exec_name=%l_exec_name:_=-%
endlocal & set %_exec_name:~5%=%l_exec_name%
exit /b 0

rem ---------------------------------------------
rem Запрашивает подтверждение выполнения процесса
rem ---------------------------------------------
:choice_process
setlocal
set _proc_name=%~0
set _exec_name=%~1
set _res_id=%~2
set _delay=%~3
set _def_choice=%~4
set _res_val=%~5
set _choice=%~6

if not defined _res_id if not defined _res_val set _res_id=ProcessingChoice
if not defined _delay set _delay=%DEF_DELAY%
if not defined _def_choice set _def_choice=Y
if not defined _choice set _choice=%YN_CHOICE%

if defined _exec_name (
	set l_exec_name=%_exec_name:~0,1%
	if "%l_exec_name%" EQU ":" (
		call :get_exec_name "%l_exec_name%"
	) else (
		set exec_name=%_exec_name%
	)
)
if defined _res_id (
	call :get_res_val -rf:"%menus_file%" -ri:%_res_id% -v1:%_delay% -v2:"%exec_name%"
) else (
	set res_val=%_res_val%
)
rem ChangeColor 15 0
%ChangeColor_15_0%
1>nul chcp 1251
Choice /C %_choice% /T %_delay% /D %_def_choice% /M "%res_val%"
set l_result=%ERRORLEVEL%
rem echo l_result="%l_result%"
endlocal & (set "%_proc_name:~8%=%exec_name%" & set "%_proc_name:~1,6%=%l_result%" & exit /b %l_result%)

rem ---------------- EOF utils.cmd ----------------
