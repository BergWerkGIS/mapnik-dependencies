@echo off
SETLOCAL
SET EL=0
echo ------ osrm DEPS -----
:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %ROOTDIR%\scripts

CALL build_bzip2.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_zlib.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_icu.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_python.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_boost.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_expat.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_lua.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_luabind.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_wingetopt.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_stxxl.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL build_tbb.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL powershell %ROOTDIR%\scripts\package_osrm_deps.ps1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

SET ARCH=x64
if %TARGET_ARCH% EQU 32 SET ARCH=x86

for /f %%i in ('powershell Get-Date -format "yyyy.MM"') do set DATE_VERSION=%%i

SET PKGNAME=osrm-deps-win-%ARCH%-%TOOLS_VERSION%-%DATE_VERSION%.7z

cd %PKGDIR%\osrm-deps
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST %PKGNAME% DEL %PKGNAME%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
IF EXIST %ROOTDIR%\bin\%PKGNAME% DEL %ROOTDIR%\bin\%PKGNAME%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

7z a -r -mx9 %PKGNAME% osrm-deps | %windir%\system32\FIND "ing archive"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

COPY %PKGNAME% %ROOTDIR%\bin\
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO osrm-deps copied to %ROOTDIR%\bin\%PKGNAME%
GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo ----------ERROR osrm DEPS --------------

:DONE
echo ----------DONE osrm DEPS --------------

cd %ROOTDIR%
EXIT /b %EL%
