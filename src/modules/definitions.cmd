@Echo Off
rem {Copyright}
rem {License}
rem Сценарий глобальных определений и констант

::Define a BS variable containing a backspace (0x08) character
for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
rem уровни логгирования: 0 - сообщения в файл, 1 - сообщения на экран, 2 - ошибки, 3 - предупреждения, 4 - информация, 5 - отладка
set LL_FILE=0
set LL_CON=1
set LL_ERR=2
set LL_WRN=3
set LL_INF=4
set LL_DBG=5
rem уровень логгирования по умолчанию: ошибки
set DEF_LOG_LEVEL=%LL_ERR%
rem логические константы
set VL_TRUE=true
set VL_FALSE=false
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
rem задержка выбора в меню по умолчанию (сек.)
set DEF_DELAY=20
set SHORT_DELAY=10
rem признаки простого выбора пользователя в меню
set YN_CHOICE=yn
set YES=1
set NO=2
rem команды работы с реестром
set RC_GET=GET
set RC_SET=SET
set RC_ADD=ADD
set RC_DEL=DEL
rem предопределённые разделы реестра
set RH_HKLM=HKLM
set RH_HKCU=HKCU
rem направления конфертации слешей в путях к файлам
set CSD_WIN=WIN
set CSD_NIX=NIX
rem признаки конвертации регистра строки
set CM_UPPER=UPPER
set CM_LOWER=LOWER
rem форматы представления даты и времени
set DF_DATE_TIME=DATE_TIME
set DF_DATE_CODE=DATE_CODE
set DF_DATE=DATE
set DF_TIME=TIME
rem архитектуры (разрядность) процессора и ОС
set PA_X86=x86
set PA_X64=x64

rem ---------------- EOF definitions.cmd ----------------
