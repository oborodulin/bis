@Echo Off
rem ���� BIS: ����������� ����� ������ (��� ����� ������������� ������� ^)
setlocal EnableExtensions EnableDelayedExpansion

set str=the~ quick@ brown# fox$ jumps over the^: lazy dog ��, ���� ���_ ���? �����+ ���� [�������] � {����}.

call :len "%str%" str_len

if %str_len% NEQ 99 endlocal & exit /b 10

endlocal & exit /b 0
rem ---------------- EOF test_wb_len.cmd ----------------
