@Echo Off
rem “ест сценари€ преобразовани€ регистра строки: прописные в строчные и наоборот
setlocal EnableExtensions EnableDelayedExpansion
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 2
rem подставл€ем в рамках теста необходимый ресурсный файл
set g_res_file=%src_dir%..\bis\resources\strings_ru.txt

set src_str=THe~ QuICk@ BrOWn# Fox$ JumPS OVER thE^: LazY dOg Ёй, ∆лоЅ √ƒе_ т”«? ѕря„ь+ ёЌых [сЏ®мўиц] ¬ {шкј‘}.
set lower_str=the~ quick@ brown# fox$ jumps over the^: lazy dog эй, жлоб где_ туз? пр€чь+ юных [съЄмщиц] в {шкаф}.
set upper_str=THE~ QUICK@ BROWN# FOX$ JUMPS OVER THE^: LAZY DOG Ё…, ∆ЋќЅ √ƒ≈_ “”«? ѕ–я„№+ ёЌџ’ [—Џ®ћў»÷] ¬ {Ў ј‘}.

call :convert_case %CM_LOWER% "%src_str%" conv_str
echo.
echo "%lower_str%"
echo "%conv_str%"
if "%conv_str%" NEQ "%lower_str%" endlocal & exit /b 10

call :convert_case %CM_UPPER% "%src_str%" conv_str
echo.
echo "%upper_str%"
echo "%conv_str%"
if /i "%conv_str%" NEQ "%upper_str%" endlocal & exit /b 11

endlocal & exit /b 0
rem ---------------- EOF test_wb_convert_case.cmd ----------------