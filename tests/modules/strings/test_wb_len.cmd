@Echo Off
rem Тест BIS: определение длины строки (без учёта экранирующего символа ^)
setlocal EnableExtensions EnableDelayedExpansion

set str=the~ quick@ brown# fox$ jumps over the^: lazy dog эй, жлоб где_ туз? прячь+ юных [съёмщиц] в {шкаф}.

call :len "%str%" str_len

if %str_len% NEQ 99 endlocal & exit /b 10

endlocal & exit /b 0
rem ---------------- EOF test_wb_len.cmd ----------------
