@Echo Off
rem {Copyright}
rem {License}
rem �������� ��������� � ����������� �������� (���������) �������� ������ � ������������ ������������

setlocal EnableExtensions EnableDelayedExpansion

rem ��������� � ����������� �������� �� ���������:
set g_script_name=%~nx0

call :echo %*
if ERRORLEVEL 1 endlocal & exit /b 1

endlocal & exit /b 0

rem ---------------------------------------------
rem �������� � ���������� ������ (���������)
rem ---------------------------------------------
:echo %*
setlocal
rem ������������� ��� ����������� ��������� � ������� ��� ������ �������, � ��������� �� ������������
call :echo_res_setup %*
call :echo_res_check_setup
if ERRORLEVEL 1 endlocal & exit /b 1

if defined p_cmd if /i "%p_cmd%" EQU "GET" call :get_res_val & echo !res_val! & endlocal & exit /b !ERRORLEVEL!
rem echo "%script_hdr%" "%res_path%" "%p_res_id%"

rem ���� �������� �������� �������
if defined res_val (
	if /i "%categ_name%" NEQ "" set res_val=%categ_name%: %res_val%
	call :set_res_color %res_color% 
	call :echo_level_res "%res_val%" "%ln%" "%log_lvl%" "%categ_num%"
) else if /i "%p_res_val_empty%" EQU "%VL_TRUE%" (
	call :echo_level_res "%res_val%" "%ln%" "%log_lvl%" "%categ_num%"
) else (
	rem ����� �������� ������ �� ��� ��
	call :get_res_val
	rem echo !res_code! !res_categ! !categ_num! !categ_name! !res_val! "!result!"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

	rem ���� �� ������ ����� � ����
	if /i "!categ_name!" NEQ "%CTG_FILE%" (
		rem ���������� ���� �������� � ������ ������ �� ��������� �������
		if /i "!categ_name!" EQU "%CTG_ERR%" (
			rem ������-������
			set l_res_color=0C
			set res_val=!categ_name!-!res_code!: %p_res_id%: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_WRN%" (
			rem ������-��������������
			set l_res_color=0E
			set res_val=!categ_name!-!res_code!: %p_res_id%: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_INF%" (
			rem ������-����������
			set l_res_color=09
			set res_val=!categ_name!-!res_code!: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_FINE%" (
			rem ������-�������
			set l_res_color=08
			set res_val=!categ_name!-!res_code!: !res_val!
		) else (
			set l_res_color=%res_color%
		)
		call :set_res_color !l_res_color!
		call :echo_level_res "!res_val!" "%ln%" "%log_lvl%" "!categ_num!"
	)
)
call :echo_log "%log_path%" "%res_val%" "%categ_num%" "%log_lvl%" "%script_hdr%"
endlocal & exit /b 0

rem ---------------------------------------------
rem ������� ������ � ���-����
rem ---------------------------------------------
:echo_log _log_path _res_val _categ_num _log_lvl _script_hdr
setlocal
set _log_path=%~1
set _res_val=%~2
set _categ_num=%~3
set _log_lvl=%~4
set _script_hdr=%~5

rem ���� �� ������ ��� ����, �� ��������� ��������
if "%_log_path%" EQU "" endlocal & exit /b 1

if not exist "%_log_path%" (
	echo %_script_hdr% > "%_log_path%"
	echo. >> "%_log_path%"
)
rem FOR /F "usebackq tokens=*" %%A IN (`%modules_dir%iso_date.cmd -df:DATE_TIME 2^>nul`) DO set iso_date_time=%%A
if "%_categ_num%" EQU "" set _categ_num=0
set l_res_val=%DATE% %TIME%: %_res_val%
rem ��� ������ ������� ������ echo ������ ���� �� ��������� �������
if defined _log_lvl (
	if %_categ_num% LEQ %_log_lvl% echo %l_res_val% >> "%_log_path%"
) else (
	echo %l_res_val% >> "%_log_path%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� �������� ������� (����������)
rem (�������������: 	g_res[%res_name%][%p_res_id%]#Val
rem						g_res[%res_name%][%p_res_id%]#Code
rem						g_res[%res_name%][%p_res_id%]#Categ
rem						g_res[%res_name%][%p_res_id%]#CategNum
rem						g_res[%res_name%][%p_res_id%]#CategName)
rem ---------------------------------------------
:get_res_val _proc_param...
set _proc_name=%~0
set _proc_param=%~1

rem ���� ������� ���� �� ���� ��������, ��������� �� ��� ����� ���������
if "%_proc_param%" NEQ "" call :echo_res_setup %*
for /f %%i in ("%res_path%") do set res_name=%%~ni
set g_res_output_cnt=

rem ���� ������ ��� ����� ��������, �� ���������� ���
if defined g_res[%res_name%][%p_res_id%]#Val (
	set res_code=!g_res[%res_name%][%p_res_id%]#Code!
	set res_categ=!g_res[%res_name%][%p_res_id%]#Categ!
	set categ_num=!g_res[%res_name%][%p_res_id%]#CategNum!
	set categ_name=!g_res[%res_name%][%p_res_id%]#CategName!
	set res_val=!g_res[%res_name%][%p_res_id%]#Val!
	goto res_found
) else (
	rem ����� ��������� ����� �������
	for /F "usebackq eol=; skip=1 tokens=1-4 delims=	" %%i in ("%res_path%") do (
		rem echo �� ���������� ����� "%res_path%": "%%i" "%%j" "%%k"  "%%l"
		set l_id=%%i
		set l_code=%%j
		set l_categ=%%k
		set l_val=%%l

		if /i "!l_id!" EQU "%p_res_id%" (
			set res_code=!l_code!
			if not defined res_categ (
				set res_categ=!l_categ!
				set categ_num=!l_categ:~0,1!
				set categ_name=!l_categ:~1!
			)
			set res_val=!l_val!
			set g_res[%res_name%][%p_res_id%]#Val=!l_val!
			set g_res[%res_name%][%p_res_id%]#Code=!l_code!
			set g_res[%res_name%][%p_res_id%]#Categ=!res_categ!
			set g_res[%res_name%][%p_res_id%]#CategNum=!categ_num!
			set g_res[%res_name%][%p_res_id%]#CategName=!categ_name!
			goto res_found
		)
	)
)
set l_err_msg=ERR -1: �� ������ ������ [��=%p_res_id%] � ����� "%res_path%". ���������, ����������, ��� �������.
rem ���� �� ������ ����� � ����
if /i "%categ_name%" NEQ "%CTG_FILE%" (
	rem ChangeColor 12 0
	%ChangeColor_12_0%
	1>nul chcp %code_page% & echo !l_err_msg!
) else (
	call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
)
exit /b 1

:res_found
rem ���� �� �������� ���� ��� ����������, �� ����� ����������� ���������� � ������
set is_color_defined=%VL_FALSE%
if defined p_val_color (set is_color_defined=%VL_TRUE%) else (for /l %%i in (1,1,%colors_cnt%) do if defined p_val_color_%%i set "is_color_defined=%VL_TRUE%" & goto :color_defined)

:color_defined
if /i "%is_color_defined%" NEQ "%VL_TRUE%" goto res_val_create

rem ���� �������� ���� ��� ����������, �� ��������� ������������������ ������
call :create_res_output "%res_name%" "%p_res_id%" "%res_val%"
goto end_get_res_val

:res_val_create
rem ����������� �������� ���������� �������
for /l %%i in (1,1,%values_cnt%) do if defined p_val_%%i (call :res_bind_var "!res_val!" {%V_SYMB%%%i} p_val_%%i & set res_val=!bind_var!) else (goto end_get_res_val)

:end_get_res_val
set %_proc_name:~5%=!res_val!
exit /b 0

rem ---------------------------------------------
rem ����������� �������� ���������� �������
rem ---------------------------------------------
:res_bind_var _res_val _var _val
setlocal
set _proc_name=%~0
set _res_val=%~1
set _var=%~2
set _val=!%3!

set _res_val=!_res_val:%_var%=%_val%!

endlocal & set %_proc_name:~5%=%_res_val%
exit /b 0

rem ---------------------------------------------
rem ������ ������������������ ������ �������
rem (�������������: 	g_res_tpl[%_res_name%][%_res_id%][0]#Cnt
rem 					g_res_tpl[%_res_name%][%_res_id%][!er!]#Part
rem 					g_res_output_cnt
rem						g_res_output[%%j]#Part
rem 					g_res_output[%%j]#Color)
rem ---------------------------------------------
:create_res_output _res_name _res_id _res_val
set _res_name=%~1
set _res_id=%~2
set _res_val=%~3

rem ���� �������� ������ ������� ������������������ ������, �� ��������� � � ������������
if defined g_res_tpl[%_res_name%][%_res_id%][0]#Cnt goto res_parts_loop

rem ����� - ��������� ������
set l_tmp_val=%_res_val%
set er=0
set l_vars_cnt=0
:res_output_loop
for /f "tokens=1* delims={}" %%a in ("%l_tmp_val%") do (
	set l_part=%%a
	rem echo "!l_part!"
	rem ���������� �������������� �� ���������� � ���� ��, �� ��������� �� ���������� � ��������� �������
	if "!l_part:~0,1!" EQU "!V_SYMB!" (
		set l_var_num=!l_part:~1!
		set "l_check_var_num="&for /f "delims=0123456789" %%i in ("!l_var_num!") do set l_check_var_num=%%i
		if not defined l_check_var_num if !l_var_num! GEQ !l_vars_cnt! set l_vars_cnt=!l_var_num!
	)
	set g_res_tpl[%_res_name%][%_res_id%][!er!]#Part=!l_part!
	set l_tmp_val=%%b
 	set /a "er+=1"
)
if defined l_tmp_val goto :res_output_loop
set /a "g_res_tpl[%_res_name%][%_res_id%][0]#Cnt=%er%-1"

:res_parts_loop
set g_res_output_cnt=!g_res_tpl[%_res_name%][%_res_id%][0]#Cnt!

if %g_res_output_cnt% EQU 0 set "g_res_output_cnt=" & exit /b 0
rem echo "%g_res_output_cnt%"

for /l %%j in (0,1,%g_res_output_cnt%) do (
	set l_res_part=!g_res_tpl[%_res_name%][%_res_id%][%%j]#Part!

	set $check_part=!l_res_part!
	for /l %%i in (1,1,%l_vars_cnt%) do (
		if "!l_res_part!" EQU "!V_SYMB!%%i" (
			if defined p_val_%%i (
				set "$check_part=!p_val_%%i!" & set "l_part_color=!p_val_color_%%i!"
			) else (
				set "$check_part=" & set "l_part_color="
			)
		)
	)
	if not defined l_part_color set l_part_color=%p_val_color%
	rem ���� �� �������������� ����������, �� ������������� ���� �������
	if "!$check_part!" EQU "!l_res_part!" (
		set g_res_output[%%j]#Part=!l_res_part!
		set g_res_output[%%j]#Color=%res_color%
	) else (
		set g_res_output[%%j]#Part=!$check_part!
		set g_res_output[%%j]#Color=!l_part_color!
	)
)
exit /b 0

rem ---------------------------------------------
rem ������� ������ � ���������� �� ������ ����������
rem � ������ ������������
rem (� �������� ������ ��������� ��������� ������
rem � ��������� ������������� ��������� ������)
rem ---------------------------------------------
:echo_level_res _res_val _ln _log_lvl _categ_num
setlocal
set _res_val=%~1
set _ln=%~2
set _log_lvl=%~3
set _categ_num=%~4
rem ���� �� � ������ ������������ ��� � ��, �� ������ ������������� ����� ������, �� ������� ������
if /i "%EXEC_MODE%" NEQ "%EM_TST%" goto echo_res_any_case
if /i "%ignore_test_exec_mode%" NEQ "%VL_TRUE%" endlocal & exit /b 0
:echo_res_any_case
if "%_categ_num%" EQU "" set _categ_num=0
rem ���� ����� ������� ������������, �� ������������ ���
if "%_log_lvl%" NEQ "" (
	rem echo if %_categ_num% LEQ %_log_lvl% call :echo_res_val "%_res_val%" "%_ln%"
	if %_categ_num% LEQ %_log_lvl% call :echo_res_val "%_res_val%" "%_ln%"
) else (
	rem ����� ������ ������� �������� �������
	call :echo_res_val "%_res_val%" "%_ln%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ������� �������� ������� (����������)
rem ---------------------------------------------
:echo_res_val _res_val _ln
setlocal
set _res_val=%~1
set _ln=%~2

rem ��������� �������� ���-�� ��������� ����� �� ������ �������� �������
for /l %%i in (1,1,%before_echo_cnt%) do echo.
rem ��������� �������� ���-�� �������� ������
for /l %%i in (1,1,%right_shift_cnt%) do set "l_spaces=!l_spaces! "
rem ���� ���������� ������������������ ������, �� ������� �������� ������� �������� ��
if defined g_res_output_cnt (
	1>nul chcp %code_page%
	for /l %%j in (0,1,%g_res_output_cnt%) do (
		if defined g_res_output[%%j]#Part (
			call :set_res_color !g_res_output[%%j]#Color!
			set l_part=!g_res_output[%%j]#Part!
			call :get_end_space %%j
			rem ��� ������ ������� ������ echo ������ ���� �� ��������� �������
			if %right_shift_cnt% EQU 0 (
				echo | set /p "dummyName=!l_part!"
			) else (
				if %%j EQU 0 (
					echo | set /p "dummyName=%BS%!l_spaces!!l_part!!end_space!"
				) else (
					echo | set /p "dummyName=!l_part!!end_space!"
				)
			)
		)
	)
	if /i "%_ln%" EQU "%VL_TRUE%" echo.
) else (
	rem  ����� - ������� �������� �������
	if /i "%p_res_val_empty%" EQU "%VL_TRUE%" (
		rem ���� �������� ������� �����������
		if /i "%_ln%" EQU "%VL_TRUE%" echo.
	) else (
		1>nul chcp %code_page%
		rem  ���� ���������� �������� �������, �� ��������� ������� ������ � ������� ������
		rem ��� ������ ������� ������ echo ������ ���� �� ��������� �������
		if %right_shift_cnt% EQU 0 (
			if /i "%_ln%" EQU "%VL_TRUE%" (
				echo %_res_val%
			) else (
				echo | set /p "dummyName=%_res_val%"
			)
		) else (
			if /i "%_ln%" EQU "%VL_TRUE%" (
				echo !l_spaces!%_res_val%
			) else (
				echo | set /p "dummyName=%BS%!l_spaces!%_res_val%"
			)
		)
rem 1>&2 - ��� ������		
	)
)
rem ��������� �������� ���-�� ��������� ����� ����� ������ �������� �������
for /l %%i in (1,1,%after_echo_cnt%) do echo.
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ��� ������������� �������������� ������
rem ---------------------------------------------
:get_end_space _cur_idx
setlocal
set _proc_name=%~0
set _cur_idx=%~1

set /a l_next_id=%_cur_idx%+1
if not defined g_res_output[%l_next_id%]#Part endlocal & set "%_proc_name:~5%=" & exit /b 0

rem echo %l_next_id% "!g_res_output[%l_next_id%]#Part!"
if "!g_res_output[%l_next_id%]#Part:~0,1!" EQU " " set "l_space= "

endlocal & set %_proc_name:~5%=%l_space%
exit /b 0

rem ---------------------------------------------
rem ������������� �������� ���� �������� ��������� ������
rem ---------------------------------------------
:set_res_color _color
setlocal
set _color=%~1

if /i "%_color%" EQU "" (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
) else if /i "%_color%" EQU "08" (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
) else if /i "%_color%" EQU "09" (
	rem ChangeColor 9 0
	%ChangeColor_9_0%
) else if /i "%_color%" EQU "0A" (
	rem ChangeColor 10 0
	%ChangeColor_10_0%
) else if /i "%_color%" EQU "0B" (
	rem ChangeColor 11 0
	%ChangeColor_11_0%
) else if /i "%_color%" EQU "0C" (
	rem ChangeColor 12 0
	%ChangeColor_12_0%
) else if /i "%_color%" EQU "0D" (
	rem ChangeColor 13 0
	%ChangeColor_13_0%
) else if /i "%_color%" EQU "0E" (
	rem ChangeColor 14 0
	%ChangeColor_14_0%
) else if /i "%_color%" EQU "0F" (
	rem ChangeColor 15 0
	%ChangeColor_15_0%
) else if /i "%_color%" EQU "AA" (
	rem ChangeColor 10 10
	%ChangeColor_10_10%
) else if /i "%_color%" EQU "CC" (
	rem ChangeColor 12 12
	%ChangeColor_12_12%
) else (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ���� � �������� ������� ��������� �����
rem ---------------------------------------------
:chgcolor_setup _chgcolor_dir
set _chgcolor_dir=%~1
if [%_chgcolor_dir:~-1%] EQU [%DIR_SEP%] set _chgcolor_dir=%_chgcolor_dir:~0,-1%
if not defined chgcolor_path (
	if exist "%b2eincfilepath%" (
		set chgcolor_path=%b2eincfilepath%chgcolor.exe
	) else (
		if not exist "%_chgcolor_dir%%DIR_SEP%chgcolor.exe" exit /b 1
		set chgcolor_path=%_chgcolor_dir%%DIR_SEP%chgcolor.exe
	)
	if defined chgcolor_path (
		set ChangeColor_8_0="!chgcolor_path!" 08
		set ChangeColor_9_0="!chgcolor_path!" 09
		set ChangeColor_10_0="!chgcolor_path!" 0A
		set ChangeColor_11_0="!chgcolor_path!" 0B
		set ChangeColor_12_0="!chgcolor_path!" 0C
		set ChangeColor_13_0="!chgcolor_path!" 0D
		set ChangeColor_14_0="!chgcolor_path!" 0E
		set ChangeColor_15_0="!chgcolor_path!" 0F
		set ChangeColor_10_10="!chgcolor_path!" AA
		set ChangeColor_12_12="!chgcolor_path!" CC
	)
)
exit /b 0

rem ---------------------------------------------
rem ������������� ��� ����������� ���������
rem � ������� ��� ������ �������
rem ---------------------------------------------
:echo_res_setup %*
rem ��������� � ����������� �������� �� ���������:
rem ���� ���������� �������
set DEF_RES_COLOR=08
rem ��������� ��������:
rem ����� �������� ������� ������ � ����
set CTG_FILE=FILE
rem ����� �������� ������� �� �����/� ����
set CTG_CON=CON
rem ������-������
set CTG_ERR=ERR
rem ������-��������������
set CTG_WRN=WRN
rem ������-����������
set CTG_INF=INF
rem ������-�������
set CTG_FINE=FINE

rem �������������� �������������� ����������
set V_SYMB=V

rem ����� ���������� ����������:
set res_val=
set res_categ=
set categ_num=
set categ_name=

rem ������ ���������� �������:
set echo_res_param_defs="-sh,script_hdr,%g_script_header%;-cm,p_cmd;-rf,res_path,%g_res_file%;-ri,p_res_id;-rv,res_val,~,p_res_val_empty;-rc,res_color,%DEF_RES_COLOR%;-rl,res_categ;-v,p_val_,~,~,values_cnt;-vc,p_val_color;-c,p_val_color_,~,~,colors_cnt;-ln,ln,%VL_TRUE%;-rs,right_shift_cnt,0;-be,before_echo_cnt,0;-ae,after_echo_cnt,0;-lf,log_path,%g_log_file%;-ll,log_lvl,%g_log_level%;-it,ignore_test_exec_mode,%VL_FALSE%;-cp,code_page,1251"
call :parse_params %~0 %echo_res_param_defs% %*
rem ������ ������� ����������� ����������
rem if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem ����� �������
if ERRORLEVEL 1 call :echo_res_help & endlocal & exit /b 0
if /i "%EXEC_MODE%" EQU "%EM_DBG%" call :print_params %~0

rem ��� ���������� �������� ��������, ������������� �� ���������
if not defined log_lvl set log_lvl=%DEF_LOG_LEVEL%
rem ���������� ����� ��������� �������
if defined res_categ (
	set categ_num=%res_categ:~0,1%
	set categ_name=%res_categ:~1%
)
rem ���������� ���� � �������� ������� ��������� �����
call :chgcolor_setup "%CUR_DIR%"
exit /b 0

rem ---------------------------------------------
rem ��������� ��������� ���� ����������� ����������
rem � �������� �������
rem ---------------------------------------------
:echo_res_check_setup
setlocal
rem ��������:
rem ���������� �� ������� ��� ����� ��������
if not defined p_res_id if not defined res_val if /i "%p_res_val_empty%" NEQ "%VL_TRUE%" (
	set l_err_msg=ERR -1: �� ������ �� �� �������, �� ��� ��������. �������, ����������, ���������� �� ������� ��� ��� ��������.
	rem ���� �� ������ ����� � ����
	if /i "%categ_name%" NEQ "%CTG_FILE%" (
		rem ChangeColor 12 0
		%ChangeColor_12_0%
		1>nul chcp %code_page% & echo !l_err_msg!
		call :echo_res_help
	) else (
		call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
	)
	endlocal & exit /b 1
)
if defined p_res_id if not exist "%res_path%" (
	set l_err_msg=ERR -1: ��� ������� [��=%p_res_id%] �� ������ ��������� ���� "%res_path%". ���������, ����������, ��� �������.
	rem ���� �� ������ ����� � ����
	if /i "%categ_name%" NEQ "%CTG_FILE%" (
		rem ChangeColor 12 0
		%ChangeColor_12_0%
		1>nul chcp %code_page% & echo !l_err_msg!
		call :echo_res_help
	) else (
		call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
	)
	endlocal & exit /b 1
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ������ ������� �������
rem ---------------------------------------------
:echo_res_help
setlocal
1>nul chcp %code_page%
echo.
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo Victory BIS: Resource module for Windows 7/10 v.{Current_Version}. {Copyright} {Current_Date}
rem ChangeColor 8 0 
%ChangeColor_8_0%
echo ������ ������� �������:
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo %g_script_name% [^<�����^>...]
echo.
rem ChangeColor 8 0
%ChangeColor_8_0%
echo �����:
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -sh"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :��������� ����������� ��������� (�� �����������). ����� � ���������� �������� ���������� ���������� g_script_header
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:���� � ����� �������� (�� �����������, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=���� � ���������� �������� ���������� ���������� g_res_file"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ri"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:������������� ������� (�� �����������, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=���� ������ ���� -rv"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rv"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:�������� ������� (�� �����������, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=���� ������ ���� -ri"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rc"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :���� �������� ���������� ������� (�� �����������). ������� � ����������������� ������� [08, 09, 0A, 0B, 0C, 0D, 0E, 0F]
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rl"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :������� ������������ ������� (�� �����������). �������� ��������� �������� [0FILE - ����� �������� ������� ������ � ����, 1CON - ����� �������� ������� �� �����/� ����, 2ERR - ������-������, 3WRN - ������-��������������, 4INF - ������-����������, 5FINE - ������-�������]
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v1"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :���������� ����������� 1 (�� �����������) - ������������ � �������� �������
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v2"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :���������� ����������� 2 (�� �����������) - ������������ � �������� �������
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v3"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :���������� ����������� 3 (�� �����������) - ������������ � �������� �������
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v4"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :���������� ����������� 4 (�� �����������) - ������������ � �������� �������
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -lf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :���� � ����� ���� (�� �����������). ����� � ���������� �������� ���������� ���������� g_log_file
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ll"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:������� ������������ (�� ��������� "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%DEF_LOG_LEVEL%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo ). ����� � ���������� �������� ���������� ���������� g_log_level [0 - ��������� � ����, 1 - ��������� �� �����, 2 - ������, 3 - ��������������, 4 - ����������, 5 - �������]
echo.
endlocal & exit /b 0
rem ---------------- EOF echo.cmd ----------------
