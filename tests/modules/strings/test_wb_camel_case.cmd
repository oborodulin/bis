@Echo Off
rem ���� �������� �������������� �������� ������: ������ ������� ���� - ���������, � ��������� ��������
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 2
rem ����������� � ������ ����� ����������� ��������� ����
set g_res_file=%src_dir%..\..\..\src\bis\resources\strings_ru.txt

set lower_str=the~ quick@ brown# fox$ jumps.over the^: lazy\dog ��, ����/���_ ���? �����+ ���� [�������] � {����}.
set upper_str=THE~ QUICK@ BROWN# FOX$ JUMPS.OVER THE^: LAZY\DOG ��, ����/���_ ���? �����+ ���� [�ڨ����] � {����}.
set res_str=The~ Quick@ Brown# Fox$ Jumps.Over The^: Lazy\Dog ��, ����/���_ ���? �����+ ���� [�������] � {����}.

call :camel_case "%lower_str%" conv_str
echo.
echo "%lower_str%"
echo "%conv_str%"
if "%conv_str%" NEQ "%res_str%" endlocal & exit /b 10

call :camel_case "%src_str%" conv_str
echo.
echo "%upper_str%"
echo "%conv_str%"
if /i "%conv_str%" NEQ "%res_str%" endlocal & exit /b 11

endlocal & exit /b 0
rem ---------------- EOF test_wb_camel_case.cmd ----------------