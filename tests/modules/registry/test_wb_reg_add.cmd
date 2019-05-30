@Echo Off
rem “ест сценари€ добавлени€ значени€ параметра реестра (переменна€ окружени€)
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 2
call "%~dp0set_envs.cmd" "%src_script%" "%src_dir%"
set add_value=d:\test dir2

FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_add% 2^>nul ^| findstr /i %reg_param_add% 2^>nul`) do set reg_value=%%C
echo.
echo "%reg_value%"
set $value=!reg_value:%add_value%=!
if "%$value%" NEQ "%reg_value%" endlocal & exit /b 10

call :reg -oc:%RC_ADD% -vn:%reg_param_add% -vv:"%add_value%"

FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_add% 2^>nul ^| findstr /i %reg_param_add% 2^>nul`) do set reg_value=%%C
echo.
echo "%add_value%" "%reg_value%"
if "%reg_value:~-13%" NEQ ";%add_value%" endlocal & exit /b 11

endlocal & exit /b 0
rem ---------------- EOF test_wb_reg_add.cmd ----------------
