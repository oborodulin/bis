@Echo Off
rem Тест сценария определения текущей локали ОС
setlocal EnableExtensions EnableDelayedExpansion

call :get_locale
echo "%locale%"

if /i "%locale%" NEQ "ru" if /i "%locale%" NEQ "en" endlocal & exit /b 10

endlocal & exit /b 0
rem ---------------- EOF test_wb_get_local.cmd ----------------