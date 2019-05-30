rem Сценарий установки переменных окружения для выполнения тестов

set src_script=%~1
set src_dir=%~2
rem подставляем в рамках теста необходимый ресурсный файл
set g_res_file=%src_dir%..\bis\resources\strings_ru.txt

rem для test_wb_reg_get.cmd
set key_name_get=HKCU\BISTest
set reg_param_get=TestParam
set param_val_get=fe.340.ead

set key_name=HKCU\Environment
set reg_param_add=BIS_TEST_ADD
set reg_param_del=BIS_TEST_DEL
set reg_param_set=BIS_TEST_SET

set param_val_del=c:\test_dir1;c:\test_dir2;c:\test_dir3
set param_val_add=c:\test_dir1

exit /b 0
rem ---------------- EOF set_envs.cmd ----------------