rem Сценарий установки переменных окружения для выполнения тестов

set p_tst_src_script=%~1

rem Каталоги по умолчанию:
rem системные (не меняются)
set tst_mod_dir=modules
set tst_cfg_dir=config
set tst_res_dir=resources
set tst_utl_dir=utils
rem пакетные (меняются в зависимости от настроек конкретного пакета)
set tst_bak_dat_dir=backup\data
set tst_bak_cfg_dir=backup\config
set tst_log_dir=logs
set tst_distrib_dir=distrib

rem Определение пути к тестовому конфигурационному файлу пакета
if exist "%p_tst_src_script%" for /f %%i in ("%p_tst_src_script%") do (
									set tst_cfg_dir=%%~dpi%tst_cfg_dir%\
									set tst_cfg_file=!tst_cfg_dir!test.xml
								)
rem для bis.cmd
set tst_phase[download]=download
set tst_phase[install]=install
set tst_phase[config]=config

rem параметры пакета
set tst_pkg_name=BIS-TEST
set tst_lower_pkg_name=bis-test
set tst_pkg_descr=BIS Test package
set tst_pkg_uselog=true
set tst_pkg_loglevel=5
set tst_root_setup_dir=D:\Programs
set tst_setup_dir=%tst_root_setup_dir%/${package.name}
set tst_distrib_dir=${bisdir}/%tst_distrib_dir%/${package.name}
set tst_backup_data_dir=${bisdir}/backup/data/${package.name}
set tst_backup_config_dir=${bisdir}/backup/config/${package.name}
set tst_log_dir=${bisdir}/logs/${package.name}

rem параметры модуля test-module1
set tst_mod1_name=test-module1
set tst_mod1_ver=1.0.0
set tst_mod1_descr=Test module 1
set tst_mod1_x64_url=https://windows.php.net/downloads/releases/php-7.2.7-Win32-VC15-%PA_X64%.zip
set tst_mod1_x86_url=https://windows.php.net/downloads/releases/php-7.2.7-Win32-VC15-%PA_X86%.zip
set tst_mod1_setup_dir=%tst_root_setup_dir%\%tst_lower_pkg_name%\%tst_mod1_name%
rem начиная от нуля
set tst_mod1_bin_dir_cnt=1
set tst_mod1_bin_dir1=%tst_root_setup_dir%\%tst_lower_pkg_name%\%tst_mod1_name%\bin1
set tst_mod1_bin_dir2=%tst_root_setup_dir%\%tst_lower_pkg_name%\%tst_mod1_name%\bin2
set tst_mod1_home_env=BIS_TEST_HOME
set tst_mod1_home_dir=BIS_TEST_HOME

exit /b 0
rem ---------------- EOF set_envs.cmd ----------------