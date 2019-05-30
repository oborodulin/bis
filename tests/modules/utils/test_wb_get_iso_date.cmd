@Echo Off
rem Тест сценария определения текущей даты и времени
setlocal EnableExtensions EnableDelayedExpansion

endlocal & exit /b 1

call :get_iso_date %DF_DATE_TIME%
echo "%iso_date%"
rem if /i "%iso_date%" NEQ "ru" endlocal & exit /b 10

call :get_iso_date %DF_DATE_CODE%
echo "%iso_date%"
rem if /i "%iso_date%" NEQ "ru" endlocal & exit /b 11

call :get_iso_date %DF_DATE%
echo "%iso_date%"
rem if /i "%iso_date%" NEQ "ru" endlocal & exit /b 12

call :get_iso_date %DF_TIME%
echo "%iso_date%"
rem if /i "%iso_date%" NEQ "ru" endlocal & exit /b 13

endlocal & exit /b 0
rem ---------------- EOF test_wb_get_iso_date.cmd ----------------