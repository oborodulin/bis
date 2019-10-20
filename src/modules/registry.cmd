@Echo Off
rem {Copyright}
rem {License}
rem �������� ������ � ����������� �������
rem (������ � ���������� ���������)

rem ---------------------------------------------
rem ������������ ������ � ����������� �������
rem ---------------------------------------------
:reg %*
setlocal
set _proc_name=%~0
rem ������������� ��� ����������� ��������� � ������� ��� ������ �������, � ��������� �� ������������
call :reg_setup %*
call :reg_check_setup & if ERRORLEVEL 1 endlocal & exit /b !ERRORLEVEL!

rem ��������� �������� ��������� �������
if /i "%oper_code%" NEQ "%RC_GET%" goto reg_not_get_cmd

call :get_reg_value "%oper_code%" "%key_name%" "%value_name%" 
if "%reg_value%" EQU "" call :echo -ri:RegQueryError -v1:"%value_name%" -rl:5FILE & endlocal & exit /b 1
call :echo -ri:RegGet -v1:"%key_name%" -v2:"%value_name%" -v3:"%reg_value%" -rl:5FILE

endlocal & set "%_proc_name:~1%=%reg_value%"
exit /b 0

:reg_not_get_cmd
rem ��������� �������� ��������� �������
if /i "%oper_code%" EQU "%RC_SET%" (
	call :get_reg_value "%oper_code%" "%key_name%" "%value_name%"
	if /i "!reg_value!" NEQ "%value_value%" (
		rem ������ �����
		if /i "%key_name%" EQU "%RH_HKLM%" (
			1>nul setx.exe %value_name% "%value_value%" /M
		) else (
			1>nul setx.exe %value_name% "%value_value%"
		)
		call :echo -ri:RegSet -v1:"%key_name%" -v2:"%value_name%" -v3:"%value_value%" -rl:5FILE
	)
	endlocal & exit /b 0
)
rem ���������� �������� ��������� �������
if /i "%oper_code%" EQU "%RC_ADD%" (
	call :get_reg_value "%oper_code%" "%key_name%" "%value_name%"
	set "$check_value=!reg_value:%value_value%=!"
	if /i "!$check_value!" EQU "!reg_value!" (
		if "!reg_value:~-1!"==";" set "reg_value=!reg_value:~0,-1!"
		rem ������ �����
		if /i "%key_name%" EQU "%RH_HKLM%" (
			1>nul setx.exe %value_name% "!reg_value!;%value_value%" /M
		) else (
			1>nul setx.exe %value_name% "!reg_value!;%value_value%"
		)
		call :echo -ri:RegAdd -v1:"%key_name%" -v2:"%value_name%" -v3:"%value_value%" -v4:"!reg_value!;%value_value%" -rl:5FILE
	)
	endlocal & exit /b 0
)
rem �������� ��������� ������� ��� ��� ��������
if /i "%oper_code%" EQU "%RC_DEL%" (
	rem ���� ��������� �������� ������
	if "%value_value%" NEQ "" (
		call :get_reg_value "%oper_code%" "%key_name%" "%value_name%" 
		set "new_value=!reg_value:;%value_value%=!"
		set "new_value=!new_value:%value_value%;=!"
		set "new_value=!new_value:%value_value%=!"
		if /i "!new_value!" NEQ "!reg_value!" (
			rem ������ �����
			if /i "%key_name%" EQU "%RH_HKLM%" (
				1>nul setx.exe %value_name% "!new_value!" /M
			) else (
				1>nul setx.exe %value_name% "!new_value!"
			)
		)
		call :echo -ri:RegDelVal -v1:"%key_name%" -v2:"%value_name%" -v3:"%value_value%" -v4:"!new_value!" -rl:5FILE
	) else (
		rem ������ �����
		if /i "%key_name%" EQU "%RH_HKLM%" (
			1>nul REG delete %HKLM% /F /V %value_name%
		) else (
			1>nul REG delete %HKCU% /F /V %value_name%
		)
		call :echo -ri:RegDel -v1:"%key_name%" -v2:"%value_name%" -rl:5FILE
	)
	endlocal & exit /b 0
)

call :echo -ri:RegOperUndefError -v1:"%oper_code%"
endlocal & exit /b 1

rem ---------------------------------------------
rem ���������� �������� �������� ���������� �������
rem ---------------------------------------------
:get_reg_value
setlocal
set _proc_name=%~0
set _oper_code=%~1
set _key_name=%~2
set _value_name=%~3

rem ���� ����� ���� HKLM, �� ������ �� ����
if /i "%_key_name%" EQU "%RH_HKLM%" (
	FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %HKLM% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
) else if /i "%_key_name%" EQU "%RH_HKCU%" (
	rem �������� �������� ���������� ��������� (������� �� ����� HKCU)
	FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %HKCU% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
	rem ���� �� ����������, ��
	if "!l_value!" EQU "" (
		rem ������ � ������ ��������� �������� ���������� ���������, ������� �������� �� ����� HKLM 
		if /i "%_oper_code%" EQU "%RC_GET%" (
			FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %HKLM% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
		)
	)
) else (
	rem ���� �� HKLM � �� HKCU
	FOR /F "usebackq tokens=1,2*" %%A IN (`REG QUERY %_key_name% /v %_value_name% 2^>nul ^| findstr /i %_value_name% 2^>nul`) do set l_value=%%C
)
endlocal & set %_proc_name:~5%=%l_value%
exit /b 0

rem ---------------------------------------------
rem ������������� ��� ����������� ���������
rem � ������� ��� ������ �������
rem ---------------------------------------------
:reg_setup %*
rem ������ ���������� �������:
:start_reg_params_parse
set p_prm=%~1
set p_key=%p_prm:~0,3%
set p_val=%p_prm:~4%
set p_val=%p_val:"=%

if not defined p_prm goto end_reg_params_parse

rem ������ ���������� ������ �������
if [%p_prm%] EQU [/?] set "p_key_help=%VL_TRUE%" & exit /b 1
if /i [%p_prm%] EQU [--help] set "p_key_help=%VL_TRUE%" & exit /b 1

if /i [%p_key%] EQU [-oc] set "oper_code=%p_val%"
if /i [%p_key%] EQU [-vn] set "value_name=%p_val%"
if /i [%p_key%] EQU [-vv] set "value_value=%p_val%"
if /i [%p_key%] EQU [-kn] set "key_name=%p_val%"

shift
goto start_reg_params_parse
:end_reg_params_parse

rem ���� �� ������ ����, ����� ����� ���������� ��������� ������������
if not defined key_name set key_name=%RH_HKCU%
rem echo -oc:"%oper_code%" -vn:"%value_name%" -vv:"%value_value%" -kn:"%key_name%"
exit /b 0

rem ---------------------------------------------
rem ��������� ��������� ���� ����������� ����������
rem � �������� �������
rem ---------------------------------------------
:reg_check_setup
setlocal
rem ��������:
rem ���������� �������� � ���������� �������
if "%oper_code%" EQU "" call :echo -ri:RegOperParamError -v1:"%value_name%" & call :reg_help & endlocal & exit /b 1

rem ���������� ����� ��������� �������
if "%value_name%" EQU "" call :reg_help & endlocal & exit /b 1
endlocal & exit /b 0

rem ---------------------------------------------
rem ������ ������� �������
rem ---------------------------------------------
:reg_help
echo. 1>&2
echo Victory BIS. Registry edit module for Windows 7 v.{Current_Version}. {Copyright}  {Current_Date} 1>&2
echo ������ ������� �������: 1>&2
echo %~nx0 [^<�����^>...] 1>&2
echo �����: 1>&2
echo 	-oc:���_�������� (^<help-������^|get-��������^|set-����������^|add-��������^|del-�������^>) 1>&2
echo 	-vn:���_����������_��������� 1>&2
echo 	-vv:��������_����������_��������� (����������� ��� �������� set, add; ����������� ��� del) 1>&2
echo 	-kn:���� [HKLM-�� ��������� ������^|HKCU-�� ������ ������������] (�� ��������� ������������ HKCU) 1>&2
exit /b 0
rem ---------------- EOF registry.cmd ----------------
