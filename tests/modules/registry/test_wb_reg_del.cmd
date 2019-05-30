@Echo Off
rem “ест сценари€ удалени€ значени€ параметра реестра и самого параметра (переменна€ окружени€)
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 2
call "%~dp0set_envs.cmd" "%src_script%" "%src_dir%"
set del_value1=c:\test_dir1
set test_value1=c:\test_dir2;c:\test_dir3
set del_value2=c:\test_dir3
set test_value2=c:\test_dir2


FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_del% 2^>nul ^| findstr /i %reg_param_del% 2^>nul`) do set reg_value=%%C
echo.
echo "%reg_value%"
if "%reg_value%" NEQ "%param_val_del%" endlocal & exit /b 10

call :reg -oc:%RC_DEL% -vn:%reg_param_del% -vv:"%del_value1%"

FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_del% 2^>nul ^| findstr /i %reg_param_del% 2^>nul`) do set reg_value=%%C
echo.
echo "%reg_value%"
if "%reg_value%" NEQ "%test_value1%" endlocal & exit /b 11

call :reg -oc:%RC_DEL% -vn:%reg_param_del% -vv:"%del_value2%"

FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_del% 2^>nul ^| findstr /i %reg_param_del% 2^>nul`) do set reg_value=%%C
echo.
echo "%reg_value%"
if "%reg_value%" NEQ "%test_value2%" endlocal & exit /b 12

call :reg -oc:%RC_DEL% -vn:"%reg_param_del%"

set reg_value=
FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %key_name% /v %reg_param_del% 2^>nul ^| findstr /i %reg_param_del% 2^>nul`) do set reg_value=%%C
echo.
echo "%reg_value%"
if "%reg_value%" NEQ "" endlocal & exit /b 13

endlocal & exit /b 0
rem ---------------- EOF test_wb_reg_del.cmd ----------------