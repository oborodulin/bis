@Echo Off
rem “ест BIS: работа со св€зываемыми переменными
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

rem  онтроль областей видимости переменных
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
