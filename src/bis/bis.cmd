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
call :choice_process "" ProcessingSetup & if ERRORLEVEL %NO% call :echo -ri:SetupAbort & endlocal & exit /b 0

rem Цикл отображения меню выбора конфигураций пакетов
:pkg_menu_loop
rem Сбрасываем параметры текущего модуля
set g_mod_name=
set g_mod_ver=

call :packages_menu "%p_pkg_name%" "%p_pkg_choice%"
rem "Выход"
if ERRORLEVEL 1 endlocal & exit /b 0

rem сбрасываем заданный выбор и позволяем системе завершиться самостоятельно
set p_pkg_choice=
set p_pkg_name=

rem Цикл отображения меню выбора модулей
:mod_menu_loop
 call :modules_menu "%p_mod_name%" "%p_mod_choice%" "%g_pkg_name%" "%g_pkg_descr%"
rem "Установить все модули"
if ERRORLEVEL 3 call :echo -ri:FuncNotImpl & endlocal & exit /b 0
rem "Возврат"
if ERRORLEVEL 2 goto pkg_menu_loop
rem "Выход"
if ERRORLEVEL 1 endlocal & exit /b 0

call :echo -rv:"%~0: g_mod_name=%g_mod_name%; g_mod_ver=%g_mod_ver%" -rl:5FINE

call :echo -ri:CfgFile -v1:"%g_pkg_cfg_file%"
call :echo -ri:SetupDir -v1:"!pkgs[%g_pkg_name%]#SetupDir!"

call :execute_module "%p_exec_choice%" "%g_pkg_name%" "%g_mod_name%" "%g_mod_ver%"
if ERRORLEVEL 1 (
	set l_em_res=%ERRORLEVEL%
	echo from execute_module return code: "!l_em_res!"
	pause
	exit /b !l_em_res!
)
if /i "%EXEC_MODE%" EQU "%EM_DBG%" call :print_var_values & pause
rem сбрасываем заданный выбор и позволяем системе завершиться самостоятельно
set p_mod_choice=
set p_exec_choice=
set p_mod_name=

goto mod_menu_loop

endlocal & exit /b 0

rem =======================================================================================
rem ---------------------------------------------
rem Отображение меню конфигураций пакетов
rem Возвращает: g_pkg_cfg_file g_pkg_name g_pkg_descr g_use_log g_log_level
rem ---------------------------------------------
:packages_menu _def_pkg_name _pkg_choice
if /i "%EXEC_MODE%" EQU "%EM_RUN%" CLS
set _def_pkg_name=%~1
set _pkg_choice=%~2
set l_delay=%DEF_DELAY%
set l_choice=

set g_log_file=
if /i "%p_use_log%" EQU "%VL_TRUE%" set g_log_file=%bis_log_dir%%DIR_SEP%BIS.log

if "%_def_pkg_name%" EQU "" (
	rem выводим заголовок программы
	call :print_header "%g_script_header%" "%g_user_account%" %g_uat_clr%
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
		set l_pkg_cfg_path=%bis_config_dir%%DIR_SEP%!l_pkg_cfg_file!
		rem проверяем xml-структуру конфигурациюнного файла
rem		echo %xml_val_% "!l_pkg_cfg_path!"
rem 		%xml_val_% "!l_pkg_cfg_path!"
rem 		echo %ERRORLEVEL%
rem 		pause
rem 		exit
		rem if ERRORLEVEL 1 (
		rem 	call :echo -ri:CfgValSchemaError -v1:"!l_pkg_cfg_path!"
		rem ) else (
			for /F "tokens=1-4 delims=	()" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	(" -v "./description" -o ")	" -v "./useLog" -o "	" -v "./logLevel" -n "!l_pkg_cfg_path!"') do (
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
		rem )
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
call :trim %l_pkg_cur#Name% g_pkg_name
call :set_var_value %BV_PKG_NAME% "%g_pkg_name%"
set g_pkg_cfg_file=%bis_config_dir%%DIR_SEP%%l_pkg_cur#File%
set g_pkg_descr=%l_pkg_cur#Descr%
set g_use_log=%l_pkg_cur#UseLog%
set g_log_level=%l_pkg_cur#LogLevel%

rem если параметров логгирования нет у пакета, то устанавливаем системные
if not defined g_use_log set g_use_log=%p_use_log%
if not defined g_log_level set g_log_level=%p_log_level%

call :echo -rv:"%~0: g_pkg_cfg_file=%g_pkg_cfg_file%; g_pkg_name=%g_pkg_name%; g_pkg_descr=%g_pkg_descr%; g_use_log=%g_use_log%; g_log_level=%g_log_level%" -rl:5FINE

rem определяем каталоги установки пакета
call :get_pkg_dirs "%g_pkg_name%"

rem при необходимости, если задано логгирование в пакете, переопределяем общий лог-файл на пакетный
if /i "%g_use_log%" EQU "%VL_TRUE%" (
	if not exist "!pkgs[%g_pkg_name%]#LogDir!" 1>nul MD "!pkgs[%g_pkg_name%]#LogDir!"
	set g_log_file=!pkgs[%g_pkg_name%]#LogDir!%DIR_SEP%%g_pkg_name%.log
)
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
set _mm_pkg_name=%~3
set _pkg_descr=%~4
if /i "%EXEC_MODE%" EQU "%EM_RUN%" CLS
set l_delay=%DEF_DELAY%
set l_choice=

if "%_def_mod_name%" EQU "" (
	rem выводим заголовок программы
	call :print_header "%g_script_header%" "%g_user_account%" %g_uat_clr%
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -be:1
	call :echo -rf:"%menus_file%" -ri:ChoiceModule -v1:%l_delay% -rc:0E
	call :echo -rv:"%_mm_pkg_name% [%_pkg_descr%]" -rc:0E
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

	rem call :convert_case %CM_LOWER% "!l_trim_mod_name!" l_lw_mod_name
	call :set_var_value %BV_MOD_NAME% "!l_trim_mod_name!" "%_mm_pkg_name%" "!l_trim_mod_name!"
	call :set_var_value %BV_MOD_VERSION% "!l_mod_ver!" "%_mm_pkg_name%" "!l_trim_mod_name!"

	if "%_def_mod_name%" EQU "" call :echo -rv:"%BS%         !x! - !l_mod_name! v.!l_mod_ver! " -rc:0F -cp:65001 -ln:%VL_FALSE%
	rem получаем каталог установки модуля, его каталог бинарных файлов и домашний каталог
	call :get_mod_install_dirs "%_mm_pkg_name%" "!l_mod_name!" "!l_mod_ver!"
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

if %mod_num% GEQ %x% call :echo -ri:ModMenuAbort -v1:"%_mm_pkg_name%" & exit /b 1
if %mod_num% GEQ %ret_pkg% exit /b 2
if %mod_num% GEQ %all_num% exit /b 3

:module_def
for /f "usebackq delims==# tokens=1-3,*" %%j in (`set g_mod[%mod_num%]`) do set l_mod_cur#%%k=%%l%%m

call :trim %l_mod_cur#Name% g_mod_name
set g_mod_ver=%l_mod_cur#Ver%
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
set _gpd_pkg_name=%~1
call :get_res_val -rf:"%xpaths_file%" -ri:XPathOSParams
for /F "tokens=1-5" %%a in ('%xml_sel_% "!res_val!" -v "concat(./setupDir, substring('%EMPTY_NODE%', 1 div not(./setupDir)))" -o "	" -v "concat(./distribDir, substring('%EMPTY_NODE%', 1 div not(./distribDir)))" -o "	" -v "concat(./backupDataDir, substring('%EMPTY_NODE%', 1 div not(./backupDataDir)))" -o "	" -v "concat(./backupConfigDir, substring('%EMPTY_NODE%', 1 div not(./backupConfigDir)))" -o "	" -v "concat(./logDir, substring('%EMPTY_NODE%', 1 div not(./logDir)))" -n "%g_pkg_cfg_file%"') do (
	set pkgs[%_gpd_pkg_name%]#SetupDir=%%~a
	call :binding_var "%_gpd_pkg_name%" "" "!pkgs[%_gpd_pkg_name%]#SetupDir!" pkgs[%_gpd_pkg_name%]#SetupDir
	call :set_var_value %BV_PKG_SETUP_DIR% "!pkgs[%_gpd_pkg_name%]#SetupDir!"
	if "%%~b" NEQ "%EMPTY_NODE%" (
		set pkgs[%_gpd_pkg_name%]#DistribDir=%%~b
		call :binding_var "%_gpd_pkg_name%" "" "!pkgs[%_gpd_pkg_name%]#DistribDir!" pkgs[%_gpd_pkg_name%]#DistribDir
	) else (
		set pkgs[%_gpd_pkg_name%]#DistribDir=%bis_distrib_dir%%DIR_SEP%%_gpd_pkg_name%
	)
	if "%%~c" NEQ "%EMPTY_NODE%" (
		set pkgs[%_gpd_pkg_name%]#BackupDataDir=%%~c
		call :binding_var "%_gpd_pkg_name%" "" "!pkgs[%_gpd_pkg_name%]#BackupDataDir!" pkgs[%_gpd_pkg_name%]#BackupDataDir
	) else (
		set pkgs[%_gpd_pkg_name%]#BackupDataDir=%bis_backup_data_dir%
	)
	if "%%~d" NEQ "%EMPTY_NODE%" (
		set pkgs[%_gpd_pkg_name%]#BackupConfigDir=%%~d
		call :binding_var "%_gpd_pkg_name%" "" "!pkgs[%_gpd_pkg_name%]#BackupConfigDir!" pkgs[%_gpd_pkg_name%]#BackupConfigDir
	) else (
		set pkgs[%_gpd_pkg_name%]#BackupConfigDir=%bis_backup_config_dir%
	)
	if "%%~e" NEQ "%EMPTY_NODE%" (
		set pkgs[%_gpd_pkg_name%]#LogDir=%%~e
		call :binding_var "%_gpd_pkg_name%" "" "!pkgs[%_gpd_pkg_name%]#LogDir!" pkgs[%_gpd_pkg_name%]#LogDir
	) else (
		set pkgs[%_gpd_pkg_name%]#LogDir=%bis_log_dir%%DIR_SEP%%_gpd_pkg_name%
	)
)
call :echo -ri:PkgSetupDir -v1:%_gpd_pkg_name% -v2:"!pkgs[%_gpd_pkg_name%]#SetupDir!"
call :echo -ri:PkgLogDir -v1:%_gpd_pkg_name% -v2:"!pkgs[%_gpd_pkg_name%]#LogDir!"
call :echo -ri:PkgDistribDir -v1:%_gpd_pkg_name% -v2:"!pkgs[%_gpd_pkg_name%]#DistribDir!"
call :echo -ri:PkgBackupDataDir -v1:%_gpd_pkg_name% -v2:"!pkgs[%_gpd_pkg_name%]#BackupDataDir!"
call :echo -ri:PkgBackupConfigDir -v1:%_gpd_pkg_name% -v2:"!pkgs[%_gpd_pkg_name%]#BackupConfigDir!"
exit /b 0

rem ---------------------------------------------
rem Выполняет установку заданного модуля
rem (устанавливает: 	mods[%_mod_name%]#DistribDir)
rem ---------------------------------------------
:execute_module
set _em_exec_choice=%~1
set _em_pkg_name=%~2
set _em_mod_name=%~3
set _em_mod_ver=%~4

rem получаем каталог установки модуля, его каталог бинарных файлов и домашний каталог
call :get_mod_install_dirs "%_em_pkg_name%" "%_em_mod_name%" "%_em_mod_ver%"

rem определяем каталог дистрибутива модуля (должен быть определён до :execute_choice)
call :get_mod_distrib_params "%_em_pkg_name%" "%_em_mod_name%" "%_em_mod_ver%"

if /i "%EXEC_MODE%" EQU "%EM_RUN%" cls
rem определяем установлен ли уже модуль
call :is_mod_installed "%_em_mod_name%" "%_em_mod_ver%"
rem если модуль установлен, переходим к выбору вариантов работы с модулем
if ERRORLEVEL 1 endlocal & call :execute_choice "%_em_exec_choice%" "%_em_pkg_name%" "%_em_mod_name%" "%_em_mod_ver%" & exit /b !ERRORLEVEL!

rem выполняем все фазы модуля
call :execute_mod_phases "%_em_pkg_name%" "%_em_mod_name%" "%_em_mod_ver%"
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
rem (устанавливает: 	mods[%_mod_name%]#Installed)
rem ---------------------------------------------
:execute_phase
set _ep_phase_id=%~1
set _ep_phase=%~2
set _ep_pkg_name=%~3
set _ep_mod_name=%~4
set _ep_mod_ver=%~5

call :echo -ri:ExecPhaseId -v1:"%_ep_phase_id%" -ae:1
call :choice_process "%_ep_phase_id%" ProcessingPhase
if ERRORLEVEL %NO% call :echo -ri:PhaseExecAbort -v1:"%_ep_phase_id%" & endlocal & exit /b 0
if /i "%_ep_phase%" EQU "%PH_DOWNLOAD%" call :phase_download "%_ep_pkg_name%" "%_ep_mod_name%" "%_ep_mod_ver%"
if /i "%_ep_phase%" EQU "%PH_INSTALL%" call :phase_install "%_ep_pkg_name%" "%_ep_mod_name%" "%_ep_mod_ver%"
if /i "%_ep_phase%" EQU "%PH_CONFIG%" call :phase_config "%_ep_pkg_name%" "%_ep_mod_name%" "%_ep_mod_ver%"
exit /b %ERRORLEVEL%

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
set l_mod_distrib_dir=!pkgs[%_pkg_name%]#DistribDir!%DIR_SEP%%_mod_name%%DIR_SEP%%_mod_ver%
rem получаем URL дистрибутива и имя его файла
set l_proc_arch=%proc_arch%
:get_distr_prms
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseDownload -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%l_proc_arch%
for /F "tokens=1,2" %%a in ('%xml_sel_% "%res_val%" -v "../distribUrl" -o "	" -v "../distribFile" -n "%g_pkg_cfg_file%"') do (
	set mods[%_mod_name%]#DistribUrl=%%~a
	if "%%~b" NEQ "" (
		set mods[%_mod_name%]#DistribFile=%%~b
	) else (
		set mods[%_mod_name%]#DistribFile=%%~nxa
	)
)
if %l_proc_arch% EQU %PA_X86% (
	set l_mod_distrib_dir=!l_mod_distrib_dir:%PA_X64%=%PA_X86%!
	goto end_distrib_params
)
if "!mods[%_mod_name%]#DistribUrl!" EQU "" set "l_proc_arch=%PA_X86%" & goto get_distr_prms
:end_distrib_params
rem определяем путь к дистрибутиву модуля
set mods[%_mod_name%]#DistribDir=%l_mod_distrib_dir%
call :set_var_value %BV_MOD_DISTR_DIR% "!mods[%_mod_name%]#DistribDir!"
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
rem URL может содержать спец-символы (&), обработка которых приводит к проблемам
rem echo on
rem call :echo -ri:ModDistribUrl -v1:%_mod_name% -v2:"!mods[%_mod_name%]#DistribUrl!"
rem pause
rem exit
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
rem Обеспечивает управляемую установку модуля
rem (устанавливает: 	mods[%_mod_name%]#Installed)
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

rem получаем цели фазы установки
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_INSTALL%" goals_cnt

rem проверяем установлен ли модуль
set l_mod_installed=%VL_FALSE%
call :is_mod_installed "%_mod_name%" "%_mod_ver%"
if ERRORLEVEL 1 set l_mod_installed=%VL_TRUE%

rem разбор по явным целям в порядке следования
for /l %%n in (0,1,%goals_cnt%) do ( 
	rem если модуль не установлен, то сплошное выполнение целей
	if /i "%l_mod_installed%" NEQ "%VL_TRUE%" (
		call :phase_install_goals "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!phase_goals[%%n]!"
	) else (
		rem иначе выборочное выполнение целей
		call :choice_process "!phase_goals[%%n]!" ProcessingGoal %SHORT_DELAY% N
		if ERRORLEVEL %NO% (
			call :echo -ri:GoalExecAbort -v1:"!phase_goals[%%n]!"
		) else (
			call :phase_install_goals "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!phase_goals[%%n]!"
		)
	)
	if ERRORLEVEL 1 endlocal & exit /b !ERRORLEVEL!
)
rem разбор неявных целей
call :goal_add_env "!mods[%_mod_name%]#HomeEnv!" "!mods[%_mod_name%]#HomeDir!"
call :goal_add_path_env "%_pkg_name%" "%_mod_name%"
set l_result=%ERRORLEVEL%

endlocal & (set "mods[%_mod_name%]#Installed=1" & exit /b %l_result%)

rem ---------------------------------------------
rem Выполняет цели фазы установки модуля
rem ---------------------------------------------
:phase_install_goals
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _install_goal=%~4

call :echo -ri:ExecGoal -v1:"%_install_goal%" -ae:1
if /i "%_install_goal%" EQU "%GL_UNPACK_7Z_SFX%" (
	call :goal_unpack_7z_sfx "%_mod_name%"
) else if /i "%_install_goal%" EQU "%GL_UNPACK_ZIP%" ( 
	call :goal_unpack_zip "%_mod_name%"
) else if /i "%_install_goal%" EQU "%GL_SILENT%" (
	call :goal_silent %PH_INSTALL% "%_mod_name%" "%_mod_ver%"
) else if /i "%_install_goal%" EQU "%GL_CMD_SHELL%" (
	rem call :get_exec_name "%~0"
	call :goal_cmd_shell "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%PH_INSTALL%"
)
if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

endlocal & exit /b 0

rem ---------------------------------------------
rem Создаёт каталог установки модуля
rem ---------------------------------------------
:create_mod_setup_dir
setlocal
set _mod_name=%~1

rem если задан каталог установки модуля и его нет, то создаём его
if "!mods[%_mod_name%]#SetupDir!" NEQ "" if not exist "!mods[%_mod_name%]#SetupDir!" (
	call :echo -ri:CreateModSetupDir -v1:"%_mod_name%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	1>nul MD "!mods[%_mod_name%]#SetupDir!"
	call :echoOk
)
endlocal & exit /b 0

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
			call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#SetupDir!" mods[%_mod_name%]#SetupDir
			call :convert_slashes %CSD_DEF% "!mods[%_mod_name%]#SetupDir!" mods[%_mod_name%]#SetupDir
			call :set_var_value %BV_MOD_SETUP_DIR% "!mods[%_mod_name%]#SetupDir!" "%_pkg_name%" "%_mod_name%"
			call :echo -ri:ModSetupDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#SetupDir!"
		)
		if "%%b" NEQ "%EMPTY_NODE%" set mods[%_mod_name%]#HomeEnv=%%~b
		if "%%c" NEQ "%EMPTY_NODE%" (
			set mods[%_mod_name%]#HomeDir=%%~c
			call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#HomeDir!" mods[%_mod_name%]#HomeDir
			call :convert_slashes %CSD_DEF% "!mods[%_mod_name%]#HomeDir!" mods[%_mod_name%]#HomeDir
			call :set_var_value %BV_MOD_HOME_DIR% "!mods[%_mod_name%]#HomeDir!" "%_pkg_name%" "%_mod_name%"
			call :echo -ri:ModHomeDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#HomeEnv!" -v3:"!mods[%_mod_name%]#HomeDir!"
		)
	)
)
rem получаем каталоги бинарных файлов модуля
if not defined mods[%_mod_name%]#BinDirCnt (
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathModBinDirs -v1:"%_mod_name%" -v2:"%_mod_ver%"
	set "i=0"
	for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -n "%g_pkg_cfg_file%"') do (
		set l_bin_dir=%%~a

		call :binding_var "%_pkg_name%" "%_mod_name%" "!l_bin_dir!" l_bin_dir
		call :convert_slashes %CSD_DEF% "!l_bin_dir!" l_bin_dir
		call :set_var_value !BV_MOD_BIN_DIR!%%j "!l_bin_dir!" "%_pkg_name%" "%_mod_name%"
		call :echo -ri:ModBinDir -v1:%_mod_name% -v2:"!l_bin_dir!"

		set mods[%_mod_name%]#BinDirs[!i!]=!l_bin_dir!
		set /a "i+=1"
	)
	set /a mods[%_mod_name%]#BinDirCnt=!i!-1
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
rem (устанавливает: 	mods[%_mod_name%]#Installed)
rem ---------------------------------------------
:execute_choice
set _ec_exec_choice=%~1
set _ec_pkg_name=%~2
set _ec_mod_name=%~3
set _ec_mod_ver=%~4

set l_delay=%DEF_DELAY%
set l_choice=
call :echo -rf:"%menus_file%" -ri:ExecModChoice -v1:"%_ec_mod_name%" -v2:%l_delay% -rc:0E -be:1
rem получаем фазы выполнения
call :get_mod_phases "%_ec_mod_name%" "%_ec_mod_ver%"
rem разбор по явным целям в порядке следования
set "x=1" 
for /l %%n in (0,1,!mods[%_ec_mod_name%]#PhaseCnt!) do ( 
	set l_mod_choice[!x!]#Phase=!mods[%_ec_mod_name%]#Phase[%%n]@Name!
	set l_mod_choice[!x!]#Id=!mods[%_ec_mod_name%]#Phase[%%n]@Id!
	
	if /i "!mods[%_ec_mod_name%]#Phase[%%n]@Name!" EQU "%PH_INSTALL%" (
		call :echo -rf:"%menus_file%" -ri:RepairModSetup -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_ec_mod_name%]#Phase[%%n]@Name!" EQU "%PH_CONFIG%" (
		call :echo -rf:"%menus_file%" -ri:ApplyModConfig -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_ec_mod_name%]#Phase[%%n]@Name!" EQU "%PH_BACKUP%" (
		call :echo -rf:"%menus_file%" -ri:BackupRestore -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_ec_mod_name%]#Phase[%%n]@Name!" EQU "%PH_UNINSTALL%" (
		set "l_phase_uninstall_id=!mods[%_ec_mod_name%]#Phase[%%n]@Id!"
		set "phase_uninstall_exist=%VL_TRUE%"
	)
)
rem предлагаем деинсталляцию по умолчанию
set l_mod_choice[!x!]#Phase=%PH_UNINSTALL%
if defined l_phase_uninstall_id (
	set l_mod_choice[!x!]#Id=!l_phase_uninstall_id!
) else (
	set l_mod_choice[!x!]#Id=%_ec_mod_name%-%PH_UNINSTALL% [%PH_INSTALL%]
)
set l_phase_uninstall_id=
set l_choice=!l_choice!!x!
call :echo -rf:"%menus_file%" -ri:UninstallMod -v1:%x% -rc:0F -rs:8

set /a "x+=1"
set l_choice=!l_choice!!x!
call :echo -rf:"%menus_file%" -ri:ActionNo -v1:%x% -rc:0F -rs:8 -ae:1

rem если определён выбор выполнения по умолчанию
if "%_ec_exec_choice%" NEQ "" set "exec_num=%_ec_exec_choice%" & goto execute_def

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
	call :execute_mod_phases "%_ec_pkg_name%" "%_ec_mod_name%" "%_ec_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_CONFIG%" (
	call :phase_config "%_ec_pkg_name%" "%_ec_mod_name%" "%_ec_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_BACKUP%" (
	call :phase_backup "%_ec_pkg_name%" "%_ec_mod_name%" "%_ec_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_UNINSTALL%" (
	rem получаем каталог установки модуля, его каталог бинарных файлов и домашний каталог
rem	call :get_mod_install_dirs "%_ec_mod_name%" "%_ec_mod_ver%"
	rem каталоги гарантированно получены ранее до вызова текущей процедуры

	rem если есть фаза деинсталляции, то выполяем деинсталляцию по ней, иначе - по фазе инсталляции
	if /i "%phase_uninstall_exist%" EQU "%VL_TRUE%" (
		call :phase_uninstall "%_ec_pkg_name%" "%_ec_mod_name%" "%_ec_mod_ver%"
	) else (
		call :phase_module_uninstall "%_ec_pkg_name%" "%_ec_mod_name%" "%_ec_mod_ver%"
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
		rem call :get_exec_name "%~0"
		call :goal_cmd_shell "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%PH_CONFIG%"
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

call :echoOk
endlocal & exit /b 0

rem ---------------------------------------------
rem Деинсталлирует модуль согласно фазе деинсталляции
rem (устанавливает: 	mods[%_mod_name%]#Installed)
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
rem (устанавливает: 	mods[%_mod_name%]#Installed)
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
call :create_mod_setup_dir "%_mod_name%"
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:Unpack7zSfx -v1:!mods[%_mod_name%]#DistribFile! -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%

call :get_res_val -ri:UnpackDistribFile -v1:"!mods[%_mod_name%]#DistribFile!"
start "%res_val%" /D "!mods[%_mod_name%]#SetupDir!" /WAIT "!mods[%_mod_name%]#DistribPath!" -y
rem -gm2 -InstallPath="!mods[%_mod_name%]#SetupDir!"
rem -y -o"!mods[%_mod_name%]#SetupDir!"
call :echoOk

call :echo -ri:DefUnpackDir -rc:0F -ln:%VL_FALSE%
rem так как распаковка выполняется в каталог дистрибутива, то считаем, сколько в нём каталогов и файлов, кроме самого дистрибутива
pushd "!mods[%_mod_name%]#DistribDir!" 
set "x=0" 
for /F %%i in ('dir * /b') do if /i "%%i" NEQ "!mods[%_mod_name%]#DistribFile!" set /a "x+=1" & set l_src_obj=%%i
rem echo %x% %l_src_obj%
call :echoOk
rem если требуется перенести содержимое только одного каталога
if %x% EQU 1 (
	call :echo -ri:MoveModDistribSetupDir -v1:"!mods[%_mod_name%]#DistribDir!%DIR_SEP%%l_src_obj%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	1>nul %copy_% "!mods[%_mod_name%]#DistribDir!%DIR_SEP%%l_src_obj%" "!mods[%_mod_name%]#SetupDir!" /E /MOVE
	call :echoOk
) else if %x% GTR 1 (
	rem иначе переносим все каталоги и файлы, кроме дистрибутива
	call :echo -ri:MoveUnpackSetupDir -v1:"!mods[%_mod_name%]#DistribDir!" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	for /F %%i in ('dir * /b') do if /i "%%i" NEQ "!mods[%_mod_name%]#DistribFile!" 1>nul move "!mods[%_mod_name%]#DistribDir!\%%i" "!mods[%_mod_name%]#SetupDir!"
	call :echoOk
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

start "%goal_title%" /WAIT "!mods[%_mod_name%]#DistribPath!" %l_keys%

call :echoOk

endlocal & exit /b 0

rem ---------------------------------------------
rem Распаковывает zip-архив
rem ---------------------------------------------
:goal_unpack_zip
setlocal
set _mod_name=%~1

rem КОНТРОЛЬ: не задан или отсутствует каталог установки
if "!mods[%_mod_name%]#SetupDir!" EQU "" call :echo -ri:ModSetupDirParamError -v1:"%_mod_name%" & endlocal & exit /b 1
call :create_mod_setup_dir "%_mod_name%"
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:UnpackZip -v1:!mods[%_mod_name%]#DistribFile! -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%

call :get_exec_name "%~0"
call :get_res_val -ri:UnpackDistribFile -v1:"!mods[%_mod_name%]#DistribFile!"
start "%res_val%" /WAIT "%z7_%" x "!mods[%_mod_name%]#DistribPath!" -o"!mods[%_mod_name%]#SetupDir!" -r 1> "%bis_log_dir%%DIR_SEP%%_mod_name%-%exec_name%.log" 2>&1

call :echoOk

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
call :echoOk

endlocal & exit /b 0

rem ---------------------------------------------
rem Добавляет бинарные каталоги заданного модуля 
rem в переменную среды PATH
rem (определяет похожие пути и запрашивает разрешение 
rem на их удаление: необходимо при повторной установке
rem модуля, когда первая прошла не удачно...)
rem ---------------------------------------------
:goal_add_path_env
setlocal
set _pkg_name=%~1
set _mod_name=%~2

call :print_exec_name "%~0"
rem если хотя бы один каталог не существует, то ни один не добавляем
for /l %%n in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	if not exist "!mods[%_mod_name%]#BinDirs[%%n]!" call :echo -ri:PathDirExistError -v1:"!mods[%_mod_name%]#BinDirs[%%n]!" & endlocal & exit /b 1
)
call :convert_case %CM_LOWER% "%_pkg_name%" l_cl_pkg_name
call :convert_case %CM_LOWER% "%_mod_name%" l_cl_mod_name

rem поиск и ручное удаление похожих существующих путей
set l_reg_key_name=%RH_HKCU%

:get_path_env
call :get_reg_value "" %l_reg_key_name% PATH
set l_paths=!reg_value!

:start_paths_loop
for /f "tokens=1* delims=%PATH_SEP%" %%i in ("%l_paths%") do (
	set l_path=%%~i
	for /l %%n in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
		if /i "!l_path!" EQU "!mods[%_mod_name%]#BinDirs[%%n]!" (
			set "l_bin_dir[%%n]#RegKeyName=%l_reg_key_name%"
			set "l_bin_dir[%%n]#Exist=%VL_TRUE%"
			rem echo l_bin_dir[%%n]#Exist=!l_bin_dir[%%n]#Exist!
		)
	)
	set l_next_paths=%%j
	call :convert_case %CM_LOWER% "!l_path!" l_cl_path
	set "$check_path=!l_cl_path:%l_cl_pkg_name%=!"
	set "$check_path=!$check_path:%l_cl_mod_name%=!"
	if /i "!$check_path!" NEQ "!l_cl_path!" (
		call :get_res_val -rf:"%menus_file%" -ri:ExistModPathEnv -v1:"%_mod_name%" -v2:%l_reg_key_name% -v3:"!l_path!" -v4:%DEF_DELAY%
		call :choice_process "" "" %DEF_DELAY% N "!res_val!"
		if !choice! EQU %YES% (
			call :echo -ri:DelPathEnv -v1:"!l_path!" -v2:%l_reg_key_name% -rc:0F -ln:%VL_FALSE%
			call :reg -oc:%RC_DEL% -kn:%l_reg_key_name% -vn:PATH -vv:"!l_path!"
			call :echoOk
		)
	)
	set l_paths=!l_next_paths!
)
if defined l_paths goto :start_paths_loop
rem echo on
if %l_reg_key_name% EQU %RH_HKLM% goto add_path_env
set "l_reg_key_name=%RH_HKLM%" & goto get_path_env

:add_path_env
set l_reg_key_name=%RH_HKCU%

rem добавление путей
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	rem echo l_bin_dir[%%j]#Exist=!l_bin_dir[%%j]#Exist!
	if /i "!l_bin_dir[%%j]#Exist!" EQU "%VL_TRUE%" (
		call :echo -ri:PathEnvDirExist -v1:"!l_bin_dir[%%j]#RegKeyName!" -v2:"!mods[%_mod_name%]#BinDirs[%%j]!" -rc:0F
	) else (
		call :echo -ri:AddPathEnv -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" -v2:%l_reg_key_name% -rc:0F -ln:%VL_FALSE%
		echo call :reg -oc:%RC_ADD% -kn:%l_reg_key_name% -vn:PATH -vv:"!l_bin_dir!"
		call :echoOk
	)
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Удаляет бинарные пути заданного модуля из 
rem переменной среды PATH
rem ---------------------------------------------
:goal_del_path_env
setlocal
set _mod_name=%~1

call :print_exec_name "%~0"

set l_reg_key_name=%RH_HKCU%

:del_path_env
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	call :echo -ri:DelPathEnv -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" -v2:%l_reg_key_name% -rc:0F -ln:%VL_FALSE%
	call :reg -oc:%RC_DEL% -kn:%l_reg_key_name% -vn:PATH -vv:"!l_bin_dir!"
	call :echoOk
)
if %l_reg_key_name% EQU %RH_HKLM% endlocal & exit /b 0
set "l_reg_key_name=%RH_HKLM%" & goto del_path_env

rem ---------------------------------------------
rem Добавляет переменную среды с заданным значением
rem ---------------------------------------------
:goal_add_env
setlocal
set _env=%~1
set _val=%~2

if not defined _env endlocal & exit /b 0

call :print_exec_name "%~0"

set l_reg_key_name=%RH_HKCU%

:get_env_value
call :get_reg_value "" %l_reg_key_name% "%_env%"
if defined reg_value (
	call :get_res_val -rf:"%menus_file%" -ri:DelExistRegKeyValue -v1:%l_reg_key_name% -v2:"%_env%" -v3:"%reg_value%"
	call :choice_process "" "" %DEF_DELAY% N "!res_val!"
	if !choice! EQU %YES% (
		call :echo -ri:DelEnv -v1:%l_reg_key_name% -v2:"%_env%" -rc:0F -ln:%VL_FALSE%
		call :reg -oc:%RC_DEL% -kn:%l_reg_key_name% -vn:"%_env%"
		call :echoOk
	) else (
		call :get_res_val -rf:"%menus_file%" -ri:ChangeRegKeyValue -v1:%l_reg_key_name% -v2:"%_env%" -v3:"%reg_value%" -v4:"%_val%"
		call :choice_process "" "" %DEF_DELAY% N "!res_val!"
		if !choice! EQU %YES% (
			call :set_env_value %l_reg_key_name% "%_env%" "%_val%"
			set l_is_change_env_value=%VL_TRUE%
		) else (
			call :echo -ri:ChangeRegKeyValueAbort -v1:%l_reg_key_name% -v2:"%_env%"
		)
	)
)
if /i %l_reg_key_name% EQU %RH_HKLM% (
	if /i "!l_is_change_env_value!" NEQ "%VL_TRUE%" call :set_env_value %RH_HKCU% "%_env%" "%_val%"
	endlocal & exit /b 0
)
set "l_reg_key_name=%RH_HKLM%" & goto get_env_value

rem ---------------------------------------------
rem Устанавливает заданное значение переменной среды
rem ---------------------------------------------
:set_env_value
setlocal
set _key=%~1
set _env=%~2
set _val=%~3

call :echo -ri:AddEnv -v1:%l_reg_key_name% -v2:"%_env%" -v3:"%_val%" -rc:0F -ln:%VL_FALSE%
call :convert_slashes %CSD_DEF% "%_val%" _val
call :reg -oc:%RC_SET% -kn:%l_reg_key_name% -vn:"%_env%" -vv:"%_val%"
call :echoOk
endlocal & exit /b 0

rem ---------------------------------------------
rem Удаляет переменную среды с заданным именем
rem ---------------------------------------------
:goal_del_env
setlocal
set _env=%~1

call :print_exec_name "%~0"

call :echo -ri:DelEnv -v1:%l_reg_key_name% -v2:"%_env%" -rc:0F -ln:%VL_FALSE%
call :reg -oc:%RC_DEL% -vn:"%_env%"
call :echoOk
endlocal & exit /b 0

rem ---------------------------------------------
rem Выполняет команды командного процессора
rem ---------------------------------------------
:goal_cmd_shell
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _phase=%~4
rem получаем команды процессора
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdCommands -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_phase%"
set "copy_num=0"
set "move_num=0"
set "md_num=0"
for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "name()" -n "%g_pkg_cfg_file%"') do (
	set l_cmd=%%a
	if /i "!l_cmd!" EQU "COPY" set /a "copy_num+=1" & call :cmd_copy "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" !copy_num!
	if /i "!l_cmd!" EQU "MOVE" set /a "move_num+=1" & call :cmd_move "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" !move_num!
	if /i "!l_cmd!" EQU "MD" set /a "md_num+=1" & call :cmd_md "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" !md_num!
	if /i "!l_cmd!" EQU "BATCH" call :cmd_batch "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%"
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
set _phase=%~4
set _copy_num=%~5

call :echo -ri:CmdCopy -rc:0F -ln:%VL_FALSE%

rem получаем пути файлов источников
call :get_cmd_objects XPathCmdCopySrc "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" %_copy_num% l_src_dir l_src_paths src_cnt

rem получаем пути файлов назначения
call :get_cmd_objects XPathCmdCopyDst "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" %_copy_num% l_dst_dir l_dst_paths dst_cnt

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
		call :convert_slashes %CSD_DEF% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_DEF% "%l_dst_dir%" l_dst_dir
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
		call :convert_slashes %CSD_DEF% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_DEF% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul copy /y "!l_src_paths[%%n]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
rem если указан один файл источник и несколько файлов назначения
if %src_cnt% EQU 0 if %dst_cnt% GTR %src_cnt% (
	call :convert_slashes %CSD_DEF% "!l_src_paths[0]!" l_src_paths[0]
	for /l %%n in (0,1,%dst_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[0]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[0]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[0]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_DEF% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
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
set _phase=%~4
set _move_num=%~5

call :echo -ri:CmdMove -rc:0F -ln:%VL_FALSE%

rem получаем пути файлов источников
call :get_cmd_objects XPathCmdMoveSrc "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" %_move_num% l_src_dir l_src_paths src_cnt
call :echo -rv:"%~0: XPathCmdMoveSrc _pkg_name=%_pkg_name%; _mod_name=%_mod_name%; _mod_ver=%_mod_ver%; _phase=%_phase%; _move_num=%_move_num%; l_src_dir=%l_src_dir%; src_cnt=%src_cnt%" -rl:5FINE

rem получаем пути файлов назначения
call :get_cmd_objects XPathCmdMoveDst "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_phase%" %_move_num% l_dst_dir l_dst_paths dst_cnt
call :echo -rv:"%~0: XPathCmdMoveDst _pkg_name=%_pkg_name%; _mod_name=%_mod_name%; _mod_ver=%_mod_ver%; _phase=%_phase%; _move_num=%_move_num%; l_dst_dir=%l_dst_dir%; dst_cnt=%dst_cnt%" -rl:5FINE

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
		call :convert_slashes %CSD_DEF% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_DEF% "%l_dst_dir%" l_dst_dir
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
		call :convert_slashes %CSD_DEF% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_DEF% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
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
set _phase=%~4
set _md_num=%~5

call :echo -ri:CmdMd -rc:0F -ln:%VL_FALSE%
rem получаем каталоги
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdMdDirs -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_phase%" -v4:%_md_num%
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
rem Выполняет пакет системных команд
rem ---------------------------------------------
:cmd_batch
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _phase=%~4

call :echo -ri:CmdBatch -rc:0F
rem -ln:%VL_FALSE%
rem получаем команды
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdBatch -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_phase%"
set "i=0"
for /F "tokens=*" %%a in ('%xml_sel_% "!res_val!" -v "./exec" -n "%g_pkg_cfg_file%"') do (
	set l_exec_cmd=%%~a
	call :echo -rv:"%~0: l_exec_cmd=!l_exec_cmd!" -rl:5FINE
	call :get_batch_cmd "%_pkg_name%" "%_mod_name%" "!l_exec_cmd!"
	if !ERRORLEVEL! EQU 0 (
		rem для вывода полной команды заменяем двойные кавычки одинарными
		set l_batch_cmd=!batch_cmd:"='!
		call :echo -ri:CmdBatchExec -v1:"!l_batch_cmd!" -ln:%VL_FALSE% -rl:5FINE
		call !batch_cmd!
		set l_exec_res=!ERRORLEVEL!
		if !l_exec_res! NEQ 0 (
			call :echo -ri:ResultFailNum -v1:"!l_exec_res!" -rl:5FINE
		) else (
			call :echoOk -rl:5FINE
		)
		set /a "i+=1"
	)
)
call :echo -ri:ResultCountOk -v1:%i% -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает подготовленную пакетную команду
rem (со связанными переменными и автоматическим 
rem определением исполняемого каталога)
rem Возвращает: batch_cmd
rem ---------------------------------------------
:get_batch_cmd _cmd
setlocal
set _proc_name=%~0
set _pkg_name=%~1
set _mod_name=%~2
set _cmd=%~3

call :binding_var "" "" "%_cmd%" l_exec_cmd
rem если прерван ввод параметров команды, то возвращаем код прерывания
if ERRORLEVEL 1 set "l_result=%ERRORLEVEL%" & endlocal & (set "%_proc_name:~5%=%l_exec_cmd%" & exit /b !l_result!)
rem получаем исполняемый файл команды
for /f "tokens=1* delims= " %%a in ("%l_exec_cmd%") do (
	set l_exec_file=%%~a
	for /f %%i in ("!l_exec_file!") do set l_exec_ext=%%~xi
	set l_exec_params=%%b
)
call :echo -rv:"%~0: l_exec_file=%l_exec_file%; l_exec_ext=%l_exec_ext%; l_exec_params=%l_exec_params%" -rl:5FINE
call :convert_slashes %CSD_DEF% "%l_exec_file%" l_exec_file
set "$check_file=!l_exec_file:%DIR_SEP%=!"
rem если в команде указан путь выполнения и указано расширение исполняемого файла, то возвращаем команду на исполнение как есть
if /i "%$check_file%" NEQ "%l_exec_file%" (
	if defined l_exec_ext (
		endlocal & (set "%_proc_name:~5%=%l_exec_cmd%" & exit /b 0)
	) else (
		rem при отсутствии расширения пытаемся его определить
		for %%k in (%PATHEXT%) do if exist "!l_exec_file!%%k" set "l_exec_cmd=!l_exec_file!%%k %l_exec_params%" & goto end_get_batch_cmd
	)
)
rem иначе определяем путь выполнения по бинарным каталогам текущего модуля
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	call :get_var_value_by_scope !BV_MOD_BIN_DIR!%%j "%_pkg_name%" "%_mod_name%"
	set l_exec_path=!var_value_by_scope!%DIR_SEP%%l_exec_file%
	call :echo -rv:"%~0: l_exec_path=!l_exec_path!" -rl:5FINE
	if not defined l_exec_ext for %%k in (%PATHEXT%) do if exist "!l_exec_path!%%k" set "l_exec_cmd=!l_exec_path!%%k %l_exec_params%" & goto end_get_batch_cmd
	if exist "!l_exec_path!" set "l_exec_cmd=!l_exec_path! %l_exec_params%" & goto end_get_batch_cmd
)
:end_get_batch_cmd
endlocal & set "%_proc_name:~5%=%l_exec_cmd%"
exit /b 0

rem ---------------------------------------------
rem Возвращает объекты источники или назначения
rem командной оболочки (cmd-shell)
rem ---------------------------------------------
:get_cmd_objects
set _res_id=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4
set _phase=%~5
set _cmd_num=%~6

set "i=0"
call :get_res_val -rf:"%xpaths_file%" -ri:%_res_id% -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_phase%" -v4:%_cmd_num%
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -o "	" -v "./includes/include" -n "%g_pkg_cfg_file%"') do (
	set l_dir=%%a
	set l_file=%%b
	call :echo -rv:"%~0: l_dir=!l_dir!; l_file=!l_file!" -rl:5FINE

	if "!l_file!" EQU "" call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" %7 & goto end_cmd_objects
	if "!l_file!" EQU "*" call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" %7 & goto end_cmd_objects

	set "%8[!i!]=!l_dir!%DIR_SEP%!l_file!"
	set /a "i+=1"
)
:end_cmd_objects
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
call :echoOk
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

call :echoOk
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

call :echoOk
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

rem echo on
call :echo -rv:"%~0: _var=%_var%" -rl:5FINE
if not defined _var endlocal & set "%4=" & exit /b 0
set "$bind_var=%_var:${=%"
rem если не нужно связывать переменную, то возвращаем её "как есть"
if /i "%$bind_var%" EQU "%_var%" endlocal & set "%4=%_var%" & exit /b 0

set l_vars=%_var%
:bind_vars_loop
for /f "tokens=1* delims=$}" %%i in ("!l_vars!") do (
	set l_var=%%i
	call :echo -rv:"%~0: l_var=!l_var!" -rl:5FINE
	set "$check_var=!l_var:~0,1!"
	if /i "!$check_var!" EQU "{" (
		set l_var=!l_var:~1!
		call :convert_case %CM_LOWER% "!l_var!" l_lc_var
		call :echo -rv:"%~0: _var=!_var!; l_var=!l_var!; l_lc_var=!l_lc_var!" -rl:5FINE
		rem если не определён текущий модуль то используем заданную область видимости
		if not defined g_mod_name (
			call :get_var_scope !l_lc_var! l_scope_pkg l_scope_mod
			if /i "!var_scope!" EQU "%BV_MOD_SCOPE%" (
				call :get_var_value_by_scope !l_lc_var! "%_pkg_name%" "%_mod_name%"
				set var_value=!var_value_by_scope!
			) else (
				call :get_var_value !l_lc_var!
			)
		) else (
			call :get_var_value !l_lc_var!
		)
		call :echo -rv:"%~0: var_value=!var_value!" -rl:5FINE
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
	set "$check_input_var=!l_input_var:~0,1!"
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
call :echo -rv:"%~0: _str=%_str%; _var=%_var%; _val=%_val%" -rl:5FINE
set l_bind_str=!_str:${%_var%}=%_val%!
endlocal & set %4=%l_bind_str%
exit /b 0

rem ---------------------------------------------
rem Возвращает область видимости связываемой переменной
rem Возвращает: scope_pkg scope_mod
rem ---------------------------------------------
:get_var_scope _var_name
setlocal
set _proc_name=%~0
set _svname=%~1

set l_scope_mark=%BV_PKG_SCOPE%
set "$check_var_name=%_svname:.=%"
call :echo -rv:"%~0: _svname=%_svname% - %_svname:~0,4%" -rl:5FINE
if /i "%$check_var_name%" EQU "%_svname%" (
	set l_scope_pkg=%DEF_VAR_PKG%
	set l_scope_mod=
) else if /i "%_svname:~0,4%" EQU "%BV_PKG_SCOPE%" (
	set l_scope_pkg=%g_pkg_name%
	set l_scope_mod=
	rem echo %~0: pkg.
) else if /i "%_svname:~0,4%" EQU "%BV_MOD_SCOPE%" (
	set l_scope_pkg=%g_pkg_name%
	set l_scope_mod=%g_mod_name%
	set l_scope_mark=%BV_MOD_SCOPE%
	rem echo %~0: mod.
) else (
	set l_scope_pkg=%DEF_VAR_PKG%
	set l_scope_mod=
)
call :echo -rv:"%~0: l_scope_pkg=%l_scope_pkg%; l_scope_mod=%l_scope_mod%" -rl:5FINE
endlocal & (set "%_proc_name:~5%=%l_scope_mark%" & set "%2=%l_scope_pkg%" & set "%3=%l_scope_mod%") & exit /b 0
rem определение областей видимости по другим пакетам и модулям
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
:set_var_value _var_name _var_value _svv_pkg_name _svv_mod_name
set _var_name=%~1
set _var_value=%~2
set _svv_pkg_name=%~3
set _svv_mod_name=%~4

rem echo %~0: _var_name=%_var_name%; _var_value=%_var_value%; _svv_pkg_name=%_svv_pkg_name%; _svv_mod_name=%_svv_mod_name%
rem если не задана область видимости переменной, то определяем её по имени
if not defined _svv_pkg_name (
	call :get_var_scope %_var_name% svv_scope_pkg svv_scope_mod
) else (
	set svv_scope_pkg=%_svv_pkg_name%
	set svv_scope_mod=%_svv_mod_name%
)
call :echo -rv:"%~0: svv_scope_pkg=%svv_scope_pkg%; svv_scope_mod=%svv_scope_mod%" -rl:5FINE
rem пытаемся получить значение переменной в определённой области видимости
call :get_var_value_by_scope %_var_name% %svv_scope_pkg% %svv_scope_mod%
call :echo -rv:"%~0: var_value_by_scope=%var_value_by_scope%; svv_scope_pkg=%svv_scope_pkg%; svv_scope_mod=%svv_scope_mod%" -rl:5FINE
rem pause
rem необходимо использование дополнительной переменной http://qaru.site/questions/14072091/batch-set-a-missing-operator
if defined svv_scope_mod (
	set l_curr_var_idx=!g_vars[%svv_scope_pkg%][%svv_scope_mod%]#Cnt!
) else (
	set l_curr_var_idx=!g_vars[%svv_scope_pkg%]#Cnt!
)
call :echo -rv:"%~0: l_curr_var_idx=%l_curr_var_idx%" -rl:5FINE
if defined svv_scope_mod (
	if not defined l_curr_var_idx set l_curr_var_idx=-1
	if not defined var_value_by_scope set /a "l_curr_var_idx+=1"
	set g_vars[%svv_scope_pkg%][%svv_scope_mod%][!l_curr_var_idx!]#Name=%_var_name%
	set g_vars[%svv_scope_pkg%][%svv_scope_mod%][!l_curr_var_idx!]#Val=%_var_value%
	set g_vars[%svv_scope_pkg%][%svv_scope_mod%]#Cnt=!l_curr_var_idx!
) else (
	if not defined l_curr_var_idx set l_curr_var_idx=-1
	if not defined var_value_by_scope set /a "l_curr_var_idx+=1"
	set g_vars[%svv_scope_pkg%][!l_curr_var_idx!]#Name=%_var_name%
	set g_vars[%svv_scope_pkg%][!l_curr_var_idx!]#Val=%_var_value%
	set g_vars[%svv_scope_pkg%]#Cnt=!l_curr_var_idx!
)
call :echo -rv:"%~0: l_curr_var_idx=%l_curr_var_idx%" -rl:5FINE
exit /b 0

rem ---------------------------------------------
rem Возвращает по заданному имени подстановочной 
rem переменной связываемое значение в заданной 
rem области видимости.
rem (Поиск производится как по полному совпадению имени
rem  переменной, так и по частичному - возвращается 
rem  первое попавшееся значение)
rem ---------------------------------------------
:get_var_value_by_scope _var_name _scope_pkg _scope_mod
setlocal
set _proc_name=%~0
set _var_name=%~1
set _scope_pkg=%~2
set _scope_mod=%~3

call :echo -rv:"%~0: _var_name=%_var_name%; _scope_pkg=%_scope_pkg%; _scope_mod=%_scope_mod%" -rl:5FINE
if defined _scope_mod (
	for /l %%n in (0,1,!g_vars[%_scope_pkg%][%_scope_mod%]#Cnt!) do (
		if /i "!g_vars[%_scope_pkg%][%_scope_mod%][%%n]#Name!" EQU "%_var_name%" set l_find_var_name=%VL_TRUE%
		if /i "!g_vars[%_scope_pkg%][%_scope_mod%][%%n]#Name!" EQU "%_var_name%0" set l_find_var_name=%VL_TRUE%
		if defined l_find_var_name set "l_var_value=!g_vars[%_scope_pkg%][%_scope_mod%][%%n]#Val!" & goto end_get_var_value_by_scope
	)
) else (
	for /l %%n in (0,1,!g_vars[%_scope_pkg%]#Cnt!) do (
		if /i "!g_vars[%_scope_pkg%][%%n]#Name!" EQU "%_var_name%" set l_find_var_name=%VL_TRUE%
		if /i "!g_vars[%_scope_pkg%][%%n]#Name!" EQU "%_var_name%0" set l_find_var_name=%VL_TRUE%
		if defined l_find_var_name set "l_var_value=!g_vars[%_scope_pkg%][%%n]#Val!" & goto end_get_var_value_by_scope
	)
)
:end_get_var_value_by_scope
call :echo -rv:"%~0: l_var_value=%l_var_value%" -rl:5FINE
endlocal & set "%_proc_name:~5%=%l_var_value%"
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
call :echo -rv:"%~0: _var_name=%_var_name%; scope_pkg=%scope_pkg%; scope_mod=%scope_mod%" -rl:5FINE

call :get_var_value_by_scope %_var_name% %scope_pkg% %scope_mod%

call :echo -rv:"%~0: var_value_by_scope=%var_value_by_scope%" -rl:5FINE
endlocal & set "%_proc_name:~5%=%var_value_by_scope%"
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
	rem call :echo -rv:"%~0: j=%%j; k=%%k; l=%%l; m=%%m; n=%%n; o=%%o" -rl:5FINE
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
rem Выводит заголовок программы, а так же информацию 
rem о режиме запуска и заданном при запуске уровне 
rem логгирования
rem ---------------------------------------------
:print_header
setlocal
set _script_header=%~1
set _user_account=%~2
set _uat_clr=%~3

if /i "%is_header_printed%" EQU "%VL_TRUE%" if /i "%EXEC_MODE%" NEQ "%EM_DBG%" endlocal & exit /b 0
call :echo -rv:"%_script_header% [" -rc:08 -ln:%VL_FALSE%
call :echo -rv:"%_user_account%" -rc:%_uat_clr% -ln:%VL_FALSE%
call :echo -rv:"; MODE: %EXEC_MODE%" -rc:0F -ln:%VL_FALSE%
if defined p_use_log call :echo -rv:"; LOG_LEVEL: %p_log_level%" -rc:0F -ln:%VL_FALSE%
call :echo -rv:"]" -rc:08
endlocal & set is_header_printed=%VL_TRUE%
exit /b 0

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
rem Идентификаторы областей видимости связываемых переменных:
set BV_PKG_SCOPE=pkg.
set BV_MOD_SCOPE=mod.
rem Идентификаторы связываемых переменных:
set BV_BIS_DIR=bisdir
set BV_WIN_DIR=windir
set BV_PROG_FILES_DIR=env.programfiles
set BV_PROG_FILES_DIR_X86=env.programfilesx86
set BV_PKG_NAME=pkg.name
set BV_PKG_SETUP_DIR=pkg.setupdir
set BV_MOD_NAME=mod.name
set BV_MOD_VERSION=mod.version
set BV_MOD_SETUP_DIR=mod.setupdir
set BV_MOD_DISTR_DIR=mod.destribdir
set BV_MOD_BIN_DIR=mod.bindir
set BV_MOD_HOME_DIR=mod.homedir

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
set bis_param_defs="-ul,p_use_log;-ll,p_log_level,%DEF_LOG_LEVEL%;-pa,proc_arch,%proc_arch%;-lc,locale;-ld,bis_log_dir,%DEF_LOG_DIR%;-dd,bis_distrib_dir,%DEF_DISTRIB_DIR%;-ud,bis_utils_dir,%DEF_UTL_DIR%;-bd,bis_backup_data_dir,%DEF_BAK_DAT_DIR%;-bc,bis_backup_config_dir,%DEF_BAK_CFG_DIR%;-md,bis_modules_dir,%DEF_MOD_DIR%;-cd,bis_config_dir,%DEF_CFG_DIR%;-rd,bis_res_dir,%DEF_RES_DIR%;-lf,p_license_file;-em,EXEC_MODE,#,%EM_RUN%;-pc,p_pkg_choice;-mc,p_mod_choice;-ec,p_exec_choice;-pn,p_pkg_name;-mn,p_mod_name"
call :parse_params %~0 %bis_param_defs% %*
rem ошибка разбора определений параметров
rem if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem вывод справки
if ERRORLEVEL 1 call :bis_help & endlocal & exit /b !ERRORLEVEL!

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

if /i "%EXEC_MODE%" EQU "%EM_DBG%" call :echo -ri:LocaleInfo -v1:%locale%

rem проверяем наличие прав администратора
call :check_permissions
if ERRORLEVEL 1 (
	set g_user_account=%UA_USR%
	set g_uat_clr=0A
) else (
	set g_user_account=%UA_ADM%
	set g_uat_clr=0C
)
rem выводим заголовок программы
call :print_header "%g_script_header%" "%g_user_account%" %g_uat_clr%

rem если не найден файл лицензии
if not exist "%p_license_file%" call :echo -ri:ProgramLicenseMsg -rc:0F
call :echo -ri:InitSetupParams -ln:%VL_FALSE% -be:1
rem call :echo -ri:ProcArchDefError -be:1
if /i "%EXEC_MODE%" EQU "%EM_DBG%" call :echo -ri:ProcArchInfo -v1:%proc_arch%

rem call :echo -rv:""
rem Формируем пути от начала текущего диска (http://www.rsdn.ru/forum/setup/2810022.hot)
for /f %%i in ("%bis_log_dir%") do set bis_log_dir=%%~dpnxi
for /f %%i in ("%bis_distrib_dir%") do set bis_distrib_dir=%%~dpnxi
for /f %%i in ("%bis_utils_dir%") do set bis_utils_dir=%%~dpnxi
for /f %%i in ("%bis_config_dir%") do set bis_config_dir=%%~dpnxi
for /f %%i in ("%bis_backup_data_dir%") do set bis_backup_data_dir=%%~dpnxi
for /f %%i in ("%bis_res_dir%") do set bis_res_dir=%%~dpnxi

set cfg_val_schema=%bis_config_dir%%DIR_SEP%bis.xsd

rem Утилиты:
rem архиватор
set z7_=%bis_utils_dir%%DIR_SEP%7-zip%DIR_SEP%7za.exe
rem копирование
set copy_=robocopy.exe
rem xml-файлы
set xml_=%bis_utils_dir%%DIR_SEP%xml.exe
set xml_sel_=%bis_utils_dir%%DIR_SEP%xml.exe sel -T -t -m
set xml_val_=%bis_utils_dir%%DIR_SEP%xml.exe val -b -e --xsd %cfg_val_schema%
rem загрузчики
set curl_=%bis_utils_dir%%DIR_SEP%curl%DIR_SEP%bin%DIR_SEP%curl.exe
set wget_=%bis_utils_dir%%DIR_SEP%wget%DIR_SEP%wget.exe

call :echoOk

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
rem наличие файла xsd-схемы проверки xml-конфигурации
if not exist "%cfg_val_schema%" call :echo -ri:CfgValSchemaExistError -v1:"%cfg_val_schema%" & endlocal & exit /b 1

call :echoOk

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
rem получаем каталоги приложений ОС
if %proc_arch% EQU %PA_X64% (
	call :set_var_value %BV_PROG_FILES_DIR% "%programfiles%"
	for %%i in ("%programfiles(x86)%") do call :set_var_value %BV_PROG_FILES_DIR_X86% "%%~si"
) else (
	call :set_var_value %BV_PROG_FILES_DIR% "%programfiles%"
	call :set_var_value %BV_PROG_FILES_DIR_X86% "%programfiles%"
)

exit /b 0

rem ---------------------------------------------
rem Формат запуска установщика пакетов
rem ---------------------------------------------
:bis_help
echo.
endlocal & exit /b 1

rem ---------------- EOF bis.cmd ----------------
