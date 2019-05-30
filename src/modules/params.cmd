rem {Copyright}
rem {License}
rem Сценарий работы с параметрами процедур и других сценариев

rem ---------------------------------------------
rem Разбирает и устанавливает значения переданным 
rem параметрам в заданной области видимости
rem ---------------------------------------------
:parse_params _scope _prm_defs %*
set _prm_scope=%~1
set _prm_defs=%~2

call :get_prm_scope "%_prm_scope%"

rem РАЗБОР ОПРЕДЕЛЕНИЙ ПАРАМЕТРОВ:
rem если ранее определения параметров были разобраны переходим к сбросу параметров и формированию значений
if defined g_prms[%prm_scope%]#Count goto end_param_defs
set l_prm_defs=%_prm_defs%
set "prm=0"
:param_defs_loop
for /f "tokens=1* delims=;" %%i in ("%l_prm_defs%") do (
	rem echo param definition: "%%i"
	set l_prm_def=%%i
	for /f "tokens=1-5 delims=," %%a in ("!l_prm_def!") do (
		rem echo param definition parts: "%%a" "%%b" "%%c" "%%d" "%%e"
		set l_key=%%~a
		if not defined l_key set "p_def_prm_err=%VL_TRUE%" & exit /b 2
		set l_name=%%~b
		if not defined l_name set "p_def_prm_err=%VL_TRUE%" & exit /b 2
		set l_def_val=%%~c
		set l_empty_var=%%~d
		set l_empty_val=%%~d
		set l_count_var=%%~e
		set g_prms[%prm_scope%][!prm!]#Key=!l_key!
		set g_prms[%prm_scope%][!prm!]#Name=!l_name!
		set g_prms[%prm_scope%][!prm!]#DefValue=
		set g_prms[%prm_scope%][!prm!]#EmptyVar=
		set g_prms[%prm_scope%][!prm!]#EmptyVal=
		set g_prms[%prm_scope%][!prm!]#CountVar=
		if defined l_def_val (
			rem если указано значение по умолчанию только в случае отсутствия параметра
			if "!l_def_val!" EQU "#" (
				rem echo not defined: "%%a" "%%b" "%%c" "%%d" "%%e"
				if defined l_empty_val if "!l_empty_val!" NEQ "~" set g_prms[%prm_scope%][!prm!]#EmptyVal=!l_empty_val!
			) else (
				if "!l_def_val!" NEQ "~" set g_prms[%prm_scope%][!prm!]#DefValue=!l_def_val!
				if defined l_empty_var (
					if "!l_empty_var!" NEQ "~" set g_prms[%prm_scope%][!prm!]#EmptyVar=!l_empty_var!
					if defined l_count_var if "!l_count_var!" NEQ "~" set g_prms[%prm_scope%][!prm!]#CountVar=!l_count_var!
				)
			)
		)
		set g_prms[%prm_scope%][!prm!]#Count=1
		set /a "prm+=1"
	)
	set l_prm_defs=%%j
)
if defined l_prm_defs goto :param_defs_loop
set /a "g_prms[%prm_scope%]#Count=%prm%-1"

:end_param_defs
rem СБРОС ПАРАМЕТРОВ:
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem echo reset: "!g_prms[%prm_scope%][%%n]#Key!" "!g_prms[%prm_scope%][%%n]#Name!" "!g_prms[%prm_scope%][%%n]#DefValue!"
	if defined !g_prms[%prm_scope%][%%n]#CountVar! (
		for /l %%i in (1,1,!g_prms[%prm_scope%][%%n]#Count!) do (
			set !g_prms[%prm_scope%][%%n]#Name!%%i=
			set g_prms[%prm_scope%][%%n]#Value%%i=
		)
		set !g_prms[%prm_scope%][%%n]#CountVar!=
		set g_prms[%prm_scope%][%%n]#Count=1
	) else if defined !g_prms[%prm_scope%][%%n]#Name! (
		rem если параметр определён,
		if not defined g_prms[%prm_scope%][%%n]#EmptyVal (
			rem то сбрасываем его только если не задано значение для не определённого параметра
			rem echo reset if not empty value: "!g_prms[%prm_scope%][%%n]#Name!"
			set !g_prms[%prm_scope%][%%n]#Name!=
			set g_prms[%prm_scope%][%%n]#Value=
		)
	)
)
rem УСТАНОВКА ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ: без контроля определения параметров
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem если указано значение по умолчанию
	if defined g_prms[%prm_scope%][%%n]#DefValue (
		rem echo set default value: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#DefValue!
		set !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#DefValue!
		set g_prms[%prm_scope%][%%n]#Value=!g_prms[%prm_scope%][%%n]#DefValue!
	)
)
rem ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПАРАМЕТРОВ:
rem переходим к аргументам-значениям параметров
shift
shift
:start_params_parse
set p_prm=%~1
set p_key=%p_prm:~0,3%
set p_val=%p_prm:~4%
set p_val=%p_val:"=%

if [%p_prm%] EQU [] goto end_params_parse

rem разбор параметров вывода справки
if [%p_prm%] EQU [/?] set "p_key_help=%VL_TRUE%" & exit /b 1
if /i [%p_prm%] EQU [--help] set "p_key_help=%VL_TRUE%" & exit /b 1

rem echo params key=value: %p_key%=%p_val%
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem разбор перечисляемых параметров
	if "!g_prms[%prm_scope%][%%n]#Key:~0,2!" EQU "!g_prms[%prm_scope%][%%n]#Key:~0,3!" (
		if "!g_prms[%prm_scope%][%%n]#CountVar!" NEQ "" (
			rem если полное совпадение ключа
			rem echo if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!!g_prms[%prm_scope%][%%n]#Count!" 
			if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!!g_prms[%prm_scope%][%%n]#Count!" (
				set !g_prms[%prm_scope%][%%n]#Name!!g_prms[%prm_scope%][%%n]#Count!=%p_val%
				set g_prms[%prm_scope%][%%n]#Value!g_prms[%prm_scope%][%%n]#Count!=%p_val%
				set !g_prms[%prm_scope%][%%n]#CountVar!=!g_prms[%prm_scope%][%%n]#Count!
				set /a "g_prms[%prm_scope%][%%n]#Count+=1"
			) else (
				rem проверка неполного совпадения ключа
				set half_key=%p_key:~0,2%
				set key_num=%p_key:~2%
				if /i "!half_key!" EQU "!g_prms[%prm_scope%][%%n]#Key!" (
					set "l_check_key_num="&for /f "delims=0123456789" %%i in ("!key_num!") do set l_check_key_num=%%i
					if not defined l_check_key_num (
						if !key_num! GTR !g_prms[%prm_scope%][%%n]#Count! (
							set g_prms[%prm_scope%][%%n]#Count=!key_num!
							set !g_prms[%prm_scope%][%%n]#Name!!g_prms[%prm_scope%][%%n]#Count!=%p_val%
							set g_prms[%prm_scope%][%%n]#Value!g_prms[%prm_scope%][%%n]#Count!=%p_val%
							set !g_prms[%prm_scope%][%%n]#CountVar!=!g_prms[%prm_scope%][%%n]#Count!
							set /a "g_prms[%prm_scope%][%%n]#Count+=1"
						)	
					)
				)
			)
		)
	) else if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!" (
		rem разбор одиночных параметров
		if defined p_val (
			rem если указано значение для не определённого параметра
			if defined g_prms[%prm_scope%][%%n]#EmptyVal (
				rem то устанавливаем заднное значение, только если он не определён
				if not defined !g_prms[%prm_scope%][%%n]#Name! (
					rem echo undefined param set value: !g_prms[%prm_scope%][%%n]#Name!=%p_val%
					set !g_prms[%prm_scope%][%%n]#Name!=%p_val%
					set g_prms[%prm_scope%][%%n]#Value=%p_val%
				)
			) else (
				set !g_prms[%prm_scope%][%%n]#Name!=%p_val%
				set g_prms[%prm_scope%][%%n]#Value=%p_val%
			)
		) else (
			rem установка признака пустого значения
			if "!g_prms[%prm_scope%][%%n]#EmptyVar!" NEQ "" set !g_prms[%prm_scope%][%%n]#EmptyVar!=true
		)
	)
)
shift
goto start_params_parse
:end_params_parse
rem УСТАНОВКА ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ: с контролем определения параметров
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem устанавливаем значение только, если задано значение для не определённого параметра и он не определён
	if defined g_prms[%prm_scope%][%%n]#EmptyVal if not defined !g_prms[%prm_scope%][%%n]#Name! (
		rem echo set empty value: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#EmptyVal!
		set !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#EmptyVal!
		set g_prms[%prm_scope%][%%n]#Value=!g_prms[%prm_scope%][%%n]#EmptyVal!
	)
)
exit /b 0

rem ---------------------------------------------
rem Печатает параметры и их значения, в т.ч.
rem значения по умолчанию
rem ---------------------------------------------
:print_params _scope
setlocal
set _prm_scope=%~1
call :get_prm_scope "%_prm_scope%"

for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	set l_start_symb=
	set l_end_bracket=
	if "!g_prms[%prm_scope%][%%n]#CountVar!" NEQ "" (
		for /l %%k in (1,1,!g_prms[%prm_scope%][%%n]#Count!) do (
			if defined !g_prms[%prm_scope%][%%n]#Name!%%k echo %prm_scope%: !g_prms[%prm_scope%][%%n]#Name!%%k=!g_prms[%prm_scope%][%%n]#Value%%k!
		)
	) else if defined !g_prms[%prm_scope%][%%n]#Name! (
				rem для вывода круглых скобок echo должны быть на отдельных строках
				echo | set /p "dummyName=%prm_scope%: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#Value! "
				set l_start_symb=^(
				if defined g_prms[%prm_scope%][%%n]#DefValue (
					echo | set /p "dummyName=!l_start_symb!!g_prms[%prm_scope%][%%n]#DefValue!"
					set "l_start_symb=,"
					set l_end_bracket=^)
				) else if defined g_prms[%prm_scope%][%%n]#EmptyVal (
					echo | set /p "dummyName=!l_start_symb!#!g_prms[%prm_scope%][%%n]#EmptyVal!"
					set "l_start_symb=,"
					set l_end_bracket=^)
				)
				if defined g_prms[%prm_scope%][%%n]#EmptyVar (
					echo | set /p "dummyName=!l_start_symb!!g_prms[%prm_scope%][%%n]#EmptyVar!"
					set l_end_bracket=^)
				)
				if defined l_end_bracket (
					echo !l_end_bracket!
				) else (
					echo.
				)
			)
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает нормированный идентификатор области 
rem видимости параметров
rem ---------------------------------------------
:get_prm_scope _scope
setlocal
set _proc_name=%~0
set _prm_scope=%~1
rem если область видимости процедура
if "%_prm_scope:~0,1%" EQU ":" (
	set l_prm_scope=%_prm_scope:~1%
) else if exist "%_prm_scope%" (
	rem если область видимости сценарий
	for /f %%i in ("%_prm_scope%") do set l_prm_scope=%%~ni
)
endlocal & set %_proc_name:~5%=%l_prm_scope%
exit /b 0
rem ---------------- EOF params.cmd ----------------
