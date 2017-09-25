@echo off
SETLOCAL
SET EL=0
echo ------ tbb -----
:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO ERROR )

cd %PKGDIR%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL %ROOTDIR%\scripts\download https://github.com/01org/tbb/archive/2018_U1.tar.gz
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
powershell "if (!$(Get-FileHash 2018_U1.tar.gz -Algorithm SHA1 | Select-String F0692F6E5665E5069D70813532B0DF34FCE7CF4D)) { Write-Error 'SHA1 mismatch' -Category InvalidData ; exit 1 }"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

if EXIST tbb ECHO found extracted sources && GOTO SRCFOUND

ECHO extracting
CALL bsdtar xfz 2018_U1.tar.gz
RENAME tbb-2018_U1 tbb
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


:SRCFOUND

cd %PKGDIR%\tbb\build\vs2013
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


:: Debug
:: MinSizeRel
:: Release
:: RelWithDebInfo
:: /verbosity q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic]

:: available configs: Release, Release-MT
msbuild makefile.sln ^
/nologo ^
/verbosity:normal ^
/t:rebuild ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration=%BUILD_TYPE% ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

XCOPY /Y /S *.dll %PKGDIR%\tbb\lib\%PLATFORM_TOOLSET%\
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

XCOPY /Y /S *.lib %PKGDIR%\tbb\lib\%PLATFORM_TOOLSET%\
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo ----------ERROR tbb --------------

:DONE
echo ----------DONE tbb --------------

cd %ROOTDIR%
EXIT /b %EL%
