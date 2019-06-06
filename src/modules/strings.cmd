rem {Copyright}
rem {License}
rem Сценарий работы с параметрами процедур и других сценариев

rem ---------------------------------------------
rem Удаляет ведущие и конечные пробелы
rem ---------------------------------------------
:trim
SET %2=%1
GOTO :EOF

rem ---------------------------------------------
rem Конвертирует слеши в обратные слеши и наоборот
rem согдасно заданному направлению (win|nix)
rem необходимо для некоторых windows-команд
rem ---------------------------------------------
:convert_slashes
setlocal
set _direction=%~1
set _var=%~2

if /i "%_direction%" EQU "%CSD_WIN%" (
	set _var=!_var:/=\!
) else (
	if /i "%_direction%" EQU "%CSD_NIX%" set _var=!_var:\=/!
)
endlocal & set "%3=%_var%"
exit /b 0

rem ---------------------------------------------
rem Возвращает длину строки
rem ---------------------------------------------
:len
setlocal enabledelayedexpansion&set l=0&set str=%~1
:len_loop
set x=!str:~%l%,1!&if not defined x (endlocal&set "%~2=%l%"&exit /b 0)
set /a l+=1&goto :len_loop

rem ---------------------------------------------
rem Конвертирует регистр (верхний/нижний) символов 
rem строки
rem ---------------------------------------------
:convert_case _case_mark _src_str conv_str
setlocal
Set _case_mark=%~1
Set _src_str=%~2

if /i "%_case_mark%" EQU "%CM_UPPER%" (
	CALL :UCase "%_src_str%"
	call :echo -ri:CaseConvert -v1:"%_src_str%" -v2:"%_case_mark%" -v3:"!UCase!"
	set l_conv_str=!UCase!
) else if /i "%_case_mark%" EQU "%CM_LOWER%" (
	CALL :LCase "%_src_str%"
	call :echo -ri:CaseConvert -v1:"%_src_str%" -v2:"%_case_mark%" -v3:"!LCase!"
	set l_conv_str=!LCase!
) else (
	call :echo -ri:CaseMarkUndefError
	rem call :exec_format & endlocal & exit /b 1
)
endlocal & set "%3=%l_conv_str%"
exit /b 0

rem ---------------------------------------------
rem Конвертирует регистр первого символа слова
rem в прописной
rem ---------------------------------------------
:capital_case _src_str conv_str
setlocal
Set _src_str=%~1

endlocal & set "%2=%l_conv_str%"
exit /b 0

rem ==========================================================================
rem Функции LCase() и UCase()
rem http://www.robvanderwoude.com/battech_convertcase.php
rem ==========================================================================
:LCase
:UCase
:: Converts to upper/lower case variable contents
:: Syntax: CALL :UCase _VAR1 _VAR2
:: Syntax: CALL :LCase _VAR1 _VAR2
:: _VAR1 = Variable NAME whose VALUE is to be converted to upper/lower case
:: _VAR2 = NAME of variable to hold the converted value
:: Note: Use variable NAMES in the CALL, not values (pass "by reference")
    setlocal enableextensions enabledelayedexpansion

	SET _UCase=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я
	SET _LCase=a b c d e f g h i j k l m n o p q r s t u v w x y z а б в г д е ё ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я
	SET _Lib_UCase_Tmp=%~1
	IF /I "%~0"==":UCase" SET _Abet=%_UCase%
	IF /I "%~0"==":LCase" SET _Abet=%_LCase%
	FOR %%Z IN (%_Abet%) DO SET _Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!
	set sProcName=%~0
    	endlocal & set %sProcName:~1%=%_Lib_UCase_Tmp%
	rem SET %2=%_Lib_UCase_Tmp%
exit /b 0

rem ---------------- EOF strings.cmd ----------------
