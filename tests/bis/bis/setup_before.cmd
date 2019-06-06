@Echo Off
rem Настройка тестового окружения (фикстуры) тестирования Victory BIS
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 3
call "%~dp0set_envs.cmd" "%src_script%"

rem параметры модуля test-module1
set mod1_setup_dir=${pkg.setupdir}/%tst_mod1_name%
set mod1_bin_dir1=${mod.setupdir}/bin1
set mod1_bin_dir2=${mod.setupdir}/bin2
set mod1_home_dir=${mod.setupdir}

if not exist "%tst_cfg_dir%" endlocal & exit /b 3

rem присоединение модулей, необходимых для работы тестов
echo PREPEND=%src_dir%..\modules\definitions.cmd
echo APPEND=%src_dir%..\modules\echo.cmd
echo APPEND=%src_dir%..\modules\params.cmd
echo APPEND=%src_dir%..\modules\registry.cmd
echo APPEND=%src_dir%..\modules\strings.cmd
echo APPEND=%src_dir%..\modules\utils.cmd

rem формирование тестового конфигурционного файла пакета
call :create_test_cfg_file "%tst_cfg_file%"

endlocal & exit /b 0

rem ---------------------------------------------
rem Создаёт тестовый конфигурационный файл пакета
rem ---------------------------------------------
:create_test_cfg_file
set _tst_cfg_file=%~1

>"%_tst_cfg_file%" (
ECHO(^<?xml version="1.0" encoding="windows-1251"?^>
ECHO(^<package^>
ECHO(    ^<name^>%tst_pkg_name%^</name^>
ECHO(    ^<description^>%tst_pkg_descr%^</description^>
ECHO(    ^<useLog^>%tst_pkg_uselog%^</useLog^>
ECHO(     ^<logLevel^>%tst_pkg_loglevel%^</logLevel^>
ECHO(    ^<proxy^>
ECHO(        ^<host^>proxyakhz.duk.root.local:3128^</host^>
ECHO(        ^<login^>ak.o.borodulin^</login^>
ECHO(        ^<password^>vavilon_61^</password^>
ECHO(    ^</proxy^>
ECHO(    ^<os^>
ECHO(        ^<windows^>
ECHO(            ^<setupDir^>%tst_setup_dir%^</setupDir^>
ECHO(            ^<distribDir^>%tst_distrib_dir%^</distribDir^>
ECHO(            ^<backupDataDir^>%tst_backup_data_dir%^</backupDataDir^>
ECHO(            ^<backupConfigDir^>%tst_backup_config_dir%^</backupConfigDir^>
ECHO(            ^<logDir^>%tst_log_dir%^</logDir^>
ECHO(            ^<modules^>
ECHO(                ^<module^>
ECHO(                    ^<name^>%tst_mod1_name%^</name^>
ECHO(                    ^<version^>%tst_mod1_ver%^</version^>
ECHO(                    ^<description^>%tst_mod1_descr%^</description^>
ECHO(                    ^<executions^>
ECHO(                        ^<execution^>
ECHO(                            ^<id^>test-module1-download^</id^>
ECHO(                            ^<phase^>%tst_phase[download]%^</phase^>
ECHO(                            ^<configuration^>
ECHO(                                ^<processor^>
ECHO(                                    ^<architecture^>%PA_X64%^</architecture^>
ECHO(                                    ^<distribUrl^>%tst_mod1_x64_url%^</distribUrl^>
ECHO(                                ^</processor^>
ECHO(                                ^<processor^>
ECHO(                                    ^<architecture^>%PA_X86%^</architecture^>
ECHO(                                    ^<distribUrl^>%tst_mod1_x86_url%^</distribUrl^>
ECHO(                                ^</processor^>
ECHO(                            ^</configuration^>
ECHO(                        ^</execution^>
ECHO(                        ^<execution^>
ECHO(                            ^<id^>test-module1-install^</id^>
ECHO(                            ^<phase^>%tst_phase[install]%^</phase^>
ECHO(                            ^<description^>Test module install^</description^>
ECHO(                            ^<goals^>
ECHO(                                ^<goal^>unpack-zip^</goal^>
ECHO(                            ^</goals^>
ECHO(                            ^<configuration^>
ECHO(                                ^<modSetupDir^>%mod1_setup_dir%^</modSetupDir^>
ECHO(                                ^<modBinDirs^>
ECHO(                                       ^<directory^>%mod1_bin_dir1%^</directory^>
ECHO(                                       ^<directory^>%mod1_bin_dir2%^</directory^>
ECHO(                                ^</modBinDirs^>
ECHO(				^<modHomeDir^>
ECHO(					^<envVar^>%tst_mod1_home_env%^</envVar^>
ECHO(					^<directory^>%mod1_home_dir%^</directory^>
ECHO(				^</modHomeDir^>
ECHO(                    ^</configuration^>
ECHO(                        ^</execution^>
ECHO(                        ^<execution^>
ECHO(                            ^<id^>test-module1-config^</id^>
ECHO(                            ^<phase^>%tst_phase[config]%^</phase^>
ECHO(                            ^<goals^>
ECHO(                                ^<goal^>cmd-shell^</goal^>
ECHO(                            ^</goals^>
ECHO(                            ^<configuration^>
ECHO(                                ^<commands^>
ECHO(                                    ^<copy^>
ECHO(                                       ^<source^>
ECHO(                                           ^<directory^>${mod.setupdir}^</directory^>
ECHO(                                           ^<includes^>
ECHO(                                               ^<include^>php.ini-development^</include^>
ECHO(                                           ^</includes^>
ECHO(                                       ^</source^>
ECHO(                                       ^<destination^>
ECHO(                                           ^<directory^>${mod.setupdir}^</directory^>
ECHO(                                           ^<includes^>
ECHO(                                               ^<include^>php.ini^</include^>
ECHO(                                           ^</includes^>
ECHO(                                       ^</destination^>
ECHO(                                    ^</copy^>
ECHO(                                    ^<md^>
ECHO(                                       ^<directory^>${mod.setupdir}/includes^</directory^>
ECHO(                                       ^<directory^>${mod.setupdir}/upload^</directory^>
ECHO(                                       ^<directory^>${mod.setupdir}/tmp^</directory^>
ECHO(                                    ^</md^>
ECHO(                                ^</commands^>
ECHO(                                ^<configFiles^>
ECHO(                                    ^<configFile^>
ECHO(                                        ^<name^>${mod.setupdir}/php.ini^</name^>
ECHO(                                        ^<comment^>;^</comment^>
ECHO(                                        ^<parameters^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>memory_limit^</name^>
ECHO(                                                ^<value^>128M^</value^>
ECHO(                                                ^<expression^>true^</expression^>
ECHO(                                                ^<description^>Максимальное количество памяти, которое может использовать скрипт^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>default_charset^</name^>
ECHO(                                                ^<value^>"UTF-8"^</value^>
ECHO(                                                ^<description^>Кодировка^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>post_max_size^</name^>
ECHO(                                                ^<value^>16M^</value^>
ECHO(                                                ^<description^>Максимальное количество данных, которые будут приняты при отправке методом POST^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>upload_max_filesize^</name^>
ECHO(                                                ^<value^>20M^</value^>
ECHO(                                                ^<description^>Максимальный размер загружаемого на сервер файла^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>max_file_uploads^</name^>
ECHO(                                                ^<value^>20^</value^>
ECHO(                                                ^<description^>Максимальное количество файлов для загрузки за один раз^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>max_execution_time^</name^>
ECHO(                                                ^<value^>30^</value^>
ECHO(                                                ^<description^>Максимальное время выполнения одного скрипта^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>bz2^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>curl^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>fileinfo^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>gd2^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>gettext^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>gmp^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>imap^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>ldap^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>mbstring^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>exif^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>mysqli^</value^>
ECHO(														^<entry^>2^</entry^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>openssl^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>pdo_mysql^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>pdo_odbc^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>pdo_pgsql^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>pdo_sqlite^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>pgsql^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>shmop^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>soap^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>sockets^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>sqlite3^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>tidy^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>xmlrpc^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<name^>extension^</name^>
ECHO(                                                ^<value^>xsl^</value^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>include_path^</name^>
ECHO(                                                ^<value^>".;${mod.setupdir}/includes"^</value^>
ECHO(                                                ^<description^>Список директорий, в которых выполняется поиск файлов функциями Include, Fopen, File, Readfile и File_get_contents^</description^>
ECHO(														^<entry^>2^</entry^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>extension_dir^</name^>
ECHO(                                                ^<value^>"${mod.setupdir}/ext"^</value^>
ECHO(                                                ^<description^>Расположение DLL-файлов расширений^</description^>
ECHO(														^<entry^>2^</entry^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>upload_tmp_dir^</name^>
ECHO(                                                ^<value^>"${mod.setupdir}/upload"^</value^>
ECHO(                                                ^<description^>Директория, в которую будут помещаться временные загружаемые файлы^</description^>
ECHO(                                            ^</param^>
ECHO(                                            ^<param^>
ECHO(                                                ^<after^>[PHP]^</after^>
ECHO(                                                ^<name^>session.save_path^</name^>
ECHO(                                                ^<value^>"${mod.setupdir}/tmp"^</value^>
ECHO(                                                ^<description^>Определяет аргумент, который передается в обработчик сохранения^</description^>
ECHO(														^<entry^>2^</entry^>
ECHO(                                            ^</param^>
ECHO(                                        ^</parameters^>
ECHO(                                    ^</configFile^>
ECHO(                                ^</configFiles^>
ECHO(                            ^</configuration^>
ECHO(                        ^</execution^>
ECHO(                    ^</executions^>
ECHO(                ^</module^>
ECHO(            ^</modules^>
ECHO(        ^</windows^>
ECHO(    ^</os^>
ECHO(^</package^>
   )
exit /b 0
rem ---------------- EOF setup_before.cmd ----------------