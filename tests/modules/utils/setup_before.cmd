@Echo Off
rem Ќастройка тестового окружени€ (фикстуры) тестировани€ сценари€ системных утилит
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 3

rem присоединение модулей, необходимых дл€ работы тестов
echo PREPEND=%src_dir%definitions.cmd
echo APPEND=%src_dir%params.cmd
echo APPEND=%src_dir%echo.cmd
echo APPEND=%src_dir%registry.cmd

exit /b 0
rem ---------------- EOF setup_before.cmd ----------------
