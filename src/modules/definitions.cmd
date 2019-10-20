@Echo Off
rem {Copyright}
rem {License}
rem Сценарий глобальных определений и констант

rem =========================================== ОБЩИЕ ===========================================
rem логические константы
set VL_TRUE=true
set VL_FALSE=false

rem =========================================== СИСТЕМНЫЕ ===========================================
rem разделитель каталогов ОС
set WIN_DIR_SEP=\
set NIX_DIR_SEP=/
set DIR_SEP=%WIN_DIR_SEP%
rem разделитель файлов ОС
set PATH_SEP=;
rem направления конфертации слешей в путях к файлам
set CSD_WIN=WIN
set CSD_NIX=NIX
set CSD_DEF=%CSD_WIN%
rem архитектуры (разрядность) процессора и ОС
set PA_X86=x86
set PA_X64=x64
rem типы прав учётной записи пользователя ОС
set UA_ADM=ADM
set UA_USR=USR

rem =========================================== ЛОГГИРОВАНИЕ ===========================================
rem уровни логгирования: 0 - сообщения в файл, 1 - сообщения на экран, 2 - ошибки, 3 - предупреждения, 4 - информация, 5 - отладка
set LL_FILE=0
set LL_CON=1
set LL_ERR=2
set LL_WRN=3
set LL_INF=4
set LL_DBG=5
rem уровень логгирования по умолчанию: ошибки
set DEF_LOG_LEVEL=%LL_ERR%

rem =========================================== РЕСУРСЫ ===========================================
::Define a BS variable containing a backspace (0x08) character
for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
rem категории: FILE - вывод значения ресурса только в файл, CON - на экран/в файл, ERR - ошибка, WRN - предупреждение, INF - информация, FINE - отладка
set CTG_FILE=FILE
set CTG_CON=CON
set CTG_ERR=ERR
set CTG_WRN=WRN
set CTG_INF=INF
set CTG_FINE=FINE
rem цвет по умолчанию выводимого ресурса
set DEF_RES_COLOR=08
rem идентификатор подстановочных переменных строкового ресурса
set V_SYMB=V
rem команды работы с ресурсами
set RESC_GET=GET

rem =========================================== ВЫПОЛНЕНИЕ ===========================================
rem режимы выполнения системы: эмуляции, тестовый, промышленный, отладки
set EM_EML=EML
set EM_TST=TST
set EM_RUN=RUN
set EM_DBG=DBG
rem коды возврата текущего режима выполнения
set CODE_EML=0
set CODE_TST=1
set CODE_RUN=2
set CODE_DBG=3

rem =========================================== UI ===========================================
rem задержка выбора в меню по умолчанию (сек.)
set DEF_DELAY=20
set SHORT_DELAY=10
rem признаки простого выбора пользователя в меню
set YN_CHOICE=yn
set YES=1
set NO=2

rem =========================================== РЕЕСТР ===========================================
rem команды работы с реестром
set RC_GET=GET
set RC_SET=SET
set RC_ADD=ADD
set RC_DEL=DEL
rem предопределённые разделы реестра: ветки и переменных окружения пользователя
set RH_HKLM=HKLM
set RH_HKCU=HKCU
rem ветки переменных окружения
set HKLM="HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
set HKCU="HKCU\Environment"

rem =========================================== ФОРМАТИРОВАНИЕ ===========================================
rem признаки конвертации регистра строки
set CM_UPPER=UPPER
set CM_LOWER=LOWER
rem форматы представления даты и времени
set DF_DATE_TIME=DATE_TIME
set DF_DATE_CODE=DATE_CODE
set DF_DATE=DATE
set DF_TIME=TIME

rem ---------------- EOF definitions.cmd ----------------