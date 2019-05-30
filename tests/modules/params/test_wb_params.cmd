@Echo Off
rem Тест сценария разбора параметров
setlocal EnableExtensions EnableDelayedExpansion

rem для контроля глобальных переменных по умолчанию
set g_script_header=Test script header
set g_log_level=
set EM_RUN=RUN
set param_defs="-sh,script_hdr,%g_script_header%;-cm,p_cmd;-em,EXEC_MODE,#,%EM_RUN%;-rf,res_path,%g_res_file%;-ri,p_res_id;-rv,res_val,~,p_res_val_empty;-rc,res_color,%DEF_RES_COLOR%;-rl,res_categ;-v,p_val_,~,~,values_cnt;-vc,p_val_color;-c,p_val_color_,~,~,colors_cnt;-ln,ln,true;-rs,right_shift_cnt,0;-be,before_echo_cnt,0;-ae,after_echo_cnt,0;-lf,log_path;-ll,log_lvl,%g_log_level%;-it,ignore_test_exec_mode;-cp,code_page,1251"

rem для контроля переменных по умолчанию
set help_file=help_file.txt
set p_green_line=true
set VL_TRUE=true
set VL_FALSE=false

rem для контроля сброса параметров
set p_cmd=GET
rem для контроля установки значений для не определённых параметров
set EXEC_MODE=TST
call :parse_params %~0 %param_defs% -em:DBG -rf:"%help_file%" -ri:KeyGreenLine -v1:"-gl" -v2:%p_green_line% -v4:%VL_TRUE% -v5:%VL_FALSE% -c1:0B -c2:0F -c4:0F -c5:0F -rs:4 -be:1 -ae:1
echo.
call :print_params %~0
echo.
rem контроль сброса параметров
if defined p_cmd endlocal & exit /b 10

rem контроль значений параметров
if "%res_path%" NEQ "%help_file%" endlocal & exit /b 11
if "%p_res_id%" NEQ "KeyGreenLine" endlocal & exit /b 12
if "%p_val_1%" NEQ "-gl" endlocal & exit /b 13
if "%p_val_2%" NEQ "%p_green_line%" endlocal & exit /b 14
if "%p_val_4%" NEQ "%VL_TRUE%" endlocal & exit /b 15
if "%p_val_5%" NEQ "%VL_FALSE%" endlocal & exit /b 16
if "%values_cnt%" NEQ "5" endlocal & exit /b 17
if "%p_val_color_1%" NEQ "0B" endlocal & exit /b 18
if "%p_val_color_2%" NEQ "0F" endlocal & exit /b 19
if "%p_val_color_4%" NEQ "0F" endlocal & exit /b 20
if "%p_val_color_5%" NEQ "0F" endlocal & exit /b 21
if "%colors_cnt%" NEQ "5" endlocal & exit /b 22
if "%right_shift_cnt%" NEQ "4" endlocal & exit /b 23
if "%before_echo_cnt%" NEQ "1" endlocal & exit /b 24
if "%after_echo_cnt%" NEQ "1" endlocal & exit /b 25
if "%script_hdr%" NEQ "%g_script_header%" endlocal & exit /b 26
if "%code_page%" NEQ "1251" endlocal & exit /b 27
if defined p_log_lvl endlocal & exit /b 28
if "%EXEC_MODE%" NEQ "TST" endlocal & exit /b 29

set EXEC_MODE=
call :parse_params %~0 %param_defs% -rv:"" -rc:0F -cp:65001 -rs:8
call :print_params %~0
echo.
if defined res_val endlocal & exit /b 30
if "%p_res_val_empty%" NEQ "true" endlocal & exit /b 31
if "%res_color%" NEQ "0F" endlocal & exit /b 32
if "%code_page%" NEQ "65001" endlocal & exit /b 33
if "%right_shift_cnt%" NEQ "8" endlocal & exit /b 34
if "%EXEC_MODE%" NEQ "%EM_RUN%" endlocal & exit /b 35

set EXEC_MODE=
call :parse_params %~0 %param_defs% -em:DBG -rv:"" -rc:0F -cp:65001 -rs:8
call :print_params %~0
if "%EXEC_MODE%" NEQ "DBG" endlocal & exit /b 36

endlocal & exit /b 0
rem ---------------- EOF test_wb_params.cmd ----------------