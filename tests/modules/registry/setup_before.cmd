@Echo Off
rem Ќастройка тестового окружени€ (фикстуры) тестировани€ сценари€ работы с реестром (переменными окружени€)

set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 3

call "%~dp0set_envs.cmd" "%src_script%" "%src_dir%"

reg add %key_name_get% /v %reg_param_get% /t REG_SZ /d %param_val_get% 1>nul
reg add %key_name% /v %reg_param_add% /t REG_EXPAND_SZ /d %param_val_add% 1>nul
reg add %key_name% /v %reg_param_del% /t REG_EXPAND_SZ /d %param_val_del% 1>nul

rem присоединение модулей, необходимых дл€ работы тестов
echo PREPEND=%src_dir%definitions.cmd
echo APPEND=%src_dir%params.cmd
echo APPEND=%src_dir%echo.cmd

exit /b 0
rem ---------------- EOF setup_before.cmd ----------------
