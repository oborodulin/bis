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
set tst_setup_dir=%tst_root_setup_dir%\%tst_pkg_name%
set tst_distrib_dir=%src_dir%distrib\%tst_pkg_name%
set tst_backup_data_dir=%src_dir%backup\data\%tst_pkg_name%
set tst_backup_cfg_dir=%src_dir%backup\config\%tst_pkg_name%
set tst_log_dir=%src_dir%logs\%tst_pkg_name%

pushd "%src_dir%"

rem ”станавливаем все необходимые параметры и ресурсы дл€ работы системы, и провер€ем их корректность
call :%src_name%_setup -pn:%tst_pkg_name% -mn:%tst_mod1_name%
call :%src_name%_check_setup
if ERRORLEVEL 1 popd & endlocal & exit /b 2

call :packages_menu "%p_pkg_name%" "%p_pkg_choice%" mod_cfg_file g_pkg_name pkg_descr use_log g_log_level

rem определ€ем общий каталог установки
call :get_pkg_dirs "%p_pkg_name%"

call :convert_slashes "win" "!pkgs[%p_pkg_name%]#SetupDir!" pkgs[%p_pkg_name%]#SetupDir
echo "!pkgs[%p_pkg_name%]#SetupDir!" "%tst_setup_dir%"
if /i "!pkgs[%p_pkg_name%]#SetupDir!" NEQ "%tst_setup_dir%" popd & endlocal & exit /b 10

call :convert_slashes "win" "!pkgs[%p_pkg_name%]#DistribDir!" pkgs[%p_pkg_name%]#DistribDir
echo "!pkgs[%p_pkg_name%]#DistribDir!" NEQ "%tst_distrib_dir%"
if /i "!pkgs[%p_pkg_name%]#DistribDir!" NEQ "%tst_distrib_dir%" popd & endlocal & exit /b 11

call :convert_slashes "win" "!pkgs[%p_pkg_name%]#BackupDataDir!" pkgs[%p_pkg_name%]#BackupDataDir
echo "!pkgs[%p_pkg_name%]#BackupDataDir!" "%tst_backup_data_dir%"
if /i "!pkgs[%p_pkg_name%]#BackupDataDir!" NEQ "%tst_backup_data_dir%" popd & endlocal & exit /b 12

call :convert_slashes "win" "!pkgs[%p_pkg_name%]#BackupConfigDir!" pkgs[%p_pkg_name%]#BackupConfigDir
echo "!pkgs[%p_pkg_name%]#BackupConfigDir!" NEQ "%tst_backup_cfg_dir%"
if /i "!pkgs[%p_pkg_name%]#BackupConfigDir!" NEQ "%tst_backup_cfg_dir%" popd & endlocal & exit /b 13

call :convert_slashes "win" "!pkgs[%p_pkg_name%]#LogDir!" pkgs[%p_pkg_name%]#LogDir
echo "!pkgs[%p_pkg_name%]#LogDir!" NEQ "%tst_log_dir%"
if /i "!pkgs[%p_pkg_name%]#LogDir!" NEQ "%tst_log_dir%" popd & endlocal & exit /b 14

popd

endlocal & exit /b 0
rem ---------------- EOF test_wb_get_pkg_dirs.cmd ----------------
