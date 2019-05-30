@Echo Off
rem Тест BIS: замена слешей на обратные слеши и наоборот в путях файловой системы
setlocal EnableExtensions EnableDelayedExpansion

set win_dir=C:\Program Files\Windows Mail\en-US
set nix_dir=C:/Program Files/Windows Mail/en-US

call :convert_slashes %CSD_WIN% "%nix_dir%" conv_dir

if "%conv_dir%" NEQ "%win_dir%" endlocal & exit /b 10

call :convert_slashes %CSD_NIX% "%win_dir%" conv_dir

if "%conv_dir%" NEQ "%nix_dir%" endlocal & exit /b 11

endlocal & exit /b 0
rem ---------------- EOF test_wb_convert_slashes.cmd ----------------
