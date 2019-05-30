@Echo Off
rem Тест BIS: определение имени выполняемого процесса (цели, фазы или команды командного процессора)
setlocal EnableExtensions EnableDelayedExpansion

set phase_name=:phase_module_uninstall
set goal_name=:goal_cmd_shell
set cmd_name=:cmd_copy

call :get_exec_name "%phase_name%"
echo.
echo "%exec_name%"
if "%exec_name%" NEQ "module-uninstall" endlocal & exit /b 10

call :get_exec_name "%goal_name%"
echo.
echo "%exec_name%"
if "%exec_name%" NEQ "cmd-shell" endlocal & exit /b 11

call :get_exec_name "%cmd_name%"
echo.
echo "%exec_name%"
if "%exec_name%" NEQ "copy" endlocal & exit /b 12

endlocal & exit /b 0
rem ---------------- EOF test_wb_proc_get_exec_name.cmd ----------------
