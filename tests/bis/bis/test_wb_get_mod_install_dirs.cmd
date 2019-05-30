@Echo Off
rem “ест BIS: определение каталогов установки пакета
setlocal EnableExtensions EnableDelayedExpansion

set src_script=%~1

if not exist "%src_script%" endlocal & exit /b 2
call "%~dp0set_envs.cmd"

for /f %%i in ("%src_script%") do (
	set src_dir=%%~dpi
	set src_name=%%~ni
)
pushd "%src_dir%"

rem ”станавливаем все необходимые параметры и ресурсы дл€ работы системы, и провер€ем их корректность
call :%src_name%_setup -pn:%tst_pkg_name% -mn:%tst_mod1_name%
call :%src_name%_check_setup
if ERRORLEVEL 1 popd & endlocal & exit /b 2

call :packages_menu "%p_pkg_name%" "%p_pkg_choice%" g_pkg_cfg_file g_pkg_name g_pkg_descr use_log g_log_level

rem определ€ем общий каталог установки
call :get_pkg_dirs "%p_pkg_name%"
call :get_mod_install_dirs "%p_pkg_name%" "%tst_mod1_name%" "%tst_mod1_ver%"

call :convert_slashes "win" "!mods[%tst_mod1_name%]#SetupDir!" mods[%tst_mod1_name%]#SetupDir
echo "!mods[%tst_mod1_name%]#SetupDir!" "%tst_mod1_setup_dir%"
if /i "!mods[%tst_mod1_name%]#SetupDir!" NEQ "%tst_mod1_setup_dir%" popd & endlocal & exit /b 10

echo "!mods[%tst_mod1_name%]#HomeEnv!" "%tst_mod1_home_env%"
if /i "!mods[%tst_mod1_name%]#HomeEnv!" NEQ "%tst_mod1_home_env%" popd & endlocal & exit /b 11

echo "!mods[%tst_mod1_name%]#BinDirCnt!"
if !mods[%tst_mod1_name%]#BinDirCnt! NEQ %tst_mod1_bin_dir_cnt% popd & endlocal & exit /b 12

for /l %%j in (0,1,!mods[%tst_mod1_name%]#BinDirCnt!) do (
	call :get_test_bin_dir mod1 %%j
	call :convert_slashes "win" "!mods[%tst_mod1_name%]#BinDirs[%%j]!" mods[%tst_mod1_name%]#BinDirs[%%j]
	echo "!mods[%tst_mod1_name%]#BinDirs[%%j]!" "!test_bin_dir!"
	if /i "!mods[%tst_mod1_name%]#BinDirs[%%j]!" NEQ "!test_bin_dir!" popd & endlocal & exit /b 13
)
popd

endlocal & exit /b 0

rem ---------------------------------------------
rem ¬озвращает тестовый каталог исполн€емых файлов
rem ---------------------------------------------
:get_test_bin_dir
setlocal
set _exec_name=%~0
set _mod_prefix=%~1
set _cur_idx=%~2

set /a bin_dir_no=%_cur_idx%+1

endlocal & set %_exec_name:~5%=!tst_%_mod_prefix%_bin_dir%bin_dir_no%!
exit /b 0
rem ---------------- EOF test_wb_get_mod_install_dirs.cmd ----------------