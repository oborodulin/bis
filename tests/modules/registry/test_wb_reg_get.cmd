@Echo Off
rem Тест сценария чтения параметра из произвольного раздела реестра
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2
if not exist "%src_script%" endlocal & exit /b 2
call "%~dp0set_envs.cmd" "%src_script%" "%src_dir%"

call :get_reg_value "%RC_GET%" "%key_name_get%" "%reg_param_get%"
echo "%reg_value%"
if "%reg_value%" NEQ "%param_val_get%" endlocal & exit /b 10

call :reg -oc:%RC_GET% -kn:"%key_name_get%" -vn:"%reg_param_get%"
echo "%reg%"
if "%reg%" NEQ "%param_val_get%" endlocal & exit /b 11

endlocal & exit /b 0
rem ---------------- EOF test_wb_reg_get.cmd ----------------
