@Echo Off
rem Тест BIS: удаление ведущих и заключительных пробелов
setlocal EnableExtensions EnableDelayedExpansion

set "str=  the "

call :trim %str% trim_str

if "%trim_str%" NEQ "the" endlocal & exit /b 10

endlocal & exit /b 0
rem ---------------- EOF test_wb_trim.cmd ----------------
