@Echo Off
rem Удаление созданных разделов и параметров реестра

call "%~dp0set_envs.cmd"

reg delete %key_name_get% /f 1>nul 2>&1
reg delete %key_name% /v %reg_param_add% /f 1>nul 2>&1
reg delete %key_name% /v %reg_param_del% /f 1>nul 2>&1
reg delete %key_name% /v %reg_param_set% /f 1>nul 2>&1
exit /b 0
rem ---------------- EOF teardown_after.cmd ----------------