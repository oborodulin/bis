@Echo Off
rem “ест сценари€ добавлени€ значени€ параметра реестра (переменна€ окружени€)
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 2
call "%~dp0set_envs.cmd" "%src_script%" "%src_dir%"
set set_value=d:\test dir2

FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_set% 2^>nul ^| findstr /i %reg_param_set% 2^>nul`) do set reg_value=%%C
echo.
echo "%reg_value%"
if "%reg_value%" NEQ "" endlocal & exit /b 10

call :reg -oc:%RC_SET% -vn:"%reg_param_set%" -vv:"%set_value%"

FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_set% 2^>nul ^| findstr /i %reg_param_set% 2^>nul`) do set reg_value=%%C
echo.
echo "%set_value%" "%reg_value%"
if "%reg_value%" NEQ "%set_value%" endlocal & exit /b 11

endlocal & exit /b 0
rem ---------------- EOF test_wb_reg_set.cmd ----------------