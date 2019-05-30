@Echo Off
rem {Copyright}
rem {License}
rem �������� ���������� ����������� � ��������

::Define a BS variable containing a backspace (0x08) character
for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
rem ������ ������������: 0 - ��������� � ����, 1 - ��������� �� �����, 2 - ������, 3 - ��������������, 4 - ����������, 5 - �������
set LL_FILE=0
set LL_CON=1
set LL_ERR=2
set LL_WRN=3
set LL_INF=4
set LL_DBG=5
rem ������� ������������ �� ���������: ������
set DEF_LOG_LEVEL=%LL_ERR%
rem ���������� ���������
set VL_TRUE=true
set VL_FALSE=false
rem ������ ���������� �������: ��������, ��������, ������������, �������
set EM_EML=EML
set EM_TST=TST
set EM_RUN=RUN
set EM_DBG=DBG
rem ���� �������� �������� ������ ����������
set CODE_EML=0
set CODE_TST=1
set CODE_RUN=2
set CODE_DBG=3
rem �������� ������ � ���� �� ��������� (���.)
set DEF_DELAY=20
set SHORT_DELAY=10
rem �������� �������� ������ ������������ � ����
set YN_CHOICE=yn
set YES=1
set NO=2
rem ������� ������ � ��������
set RC_GET=GET
set RC_SET=SET
set RC_ADD=ADD
set RC_DEL=DEL
rem ��������������� ������� �������
set RH_HKLM=HKLM
set RH_HKCU=HKCU
rem ����������� ����������� ������ � ����� � ������
set CSD_WIN=WIN
set CSD_NIX=NIX
rem �������� ����������� �������� ������
set CM_UPPER=UPPER
set CM_LOWER=LOWER
rem ������� ������������� ���� � �������
set DF_DATE_TIME=DATE_TIME
set DF_DATE_CODE=DATE_CODE
set DF_DATE=DATE
set DF_TIME=TIME
rem ����������� (�����������) ���������� � ��
set PA_X86=x86
set PA_X64=x64

rem ---------------- EOF definitions.cmd ----------------
