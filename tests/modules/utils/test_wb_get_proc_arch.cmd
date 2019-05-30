@Echo Off
rem Тест сценария определения разрядности ОС
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 2
rem подставляем в рамках теста необходимый ресурсный файл
set g_res_file=%src_dir%..\bis\resources\strings_ru.txt

call :get_proc_arch
echo.
echo "%proc_arch%"

if /i "%proc_arch%" NEQ "%PA_X64%" if /i "%proc_arch%" NEQ "%PA_X86%" endlocal & exit /b 10

endlocal & exit /b 0
rem ---------------- EOF test_wb_get_proc_arch.cmd ----------------