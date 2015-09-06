@echo off
SETLOCAL
SET EL=0
echo ------ zlib -----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL %ROOTDIR%\scripts\download zlib-%ZLIB_VERSION%.tar.gz
IF ERRORLEVEL 1 GOTO ERROR

if EXIST zlib (
  echo found extracted sources
)


SETLOCAL ENABLEDELAYEDEXPANSION
if NOT EXIST "zlib" (
  echo extracting ...
  CALL bsdtar xfz zlib-%ZLIB_VERSION%.tar.gz
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  rename zlib-%ZLIB_VERSION% zlib
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  cd %PKGDIR%\zlib
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  ECHO patching ...
  patch -N -p1 < %PATCHES%/zlib-1.2.8.diff || %SKIP_FAILED_PATCH%
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  CD %PKGDIR%\zlib\contrib\vstudio\vc11
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  ECHO removing ZLIB_WINAPI ...
  find . -iname "*.vcxproj" -exec sed -i "s/ZLIB_WINAPI;/;/g" "{}" ;
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
)
ENDLOCAL

:: reassemble with /safeseh since vs2015 requires it for win32
SET ARCH=x64
IF %TARGET_ARCH% EQU 32 SET ARCH=x86
CD %PKGDIR%\zlib\contrib\masm%ARCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
:: only ml needs the /safeseh parameter (not ml64), so this sed is a noop on bld_ml64.bat
sed -i "s/^ml /ml \/safeseh /" bld_ml%TARGET_ARCH%.bat
CALL bld_ml%TARGET_ARCH%.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:: --- build with Visual Studio
CD %PKGDIR%\zlib\contrib\vstudio\vc11
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

msbuild zlibvc.sln ^
/p:ForceImportBeforeCppTargets=%ROOTDIR%\scripts\force-debug-information-for-sln.props ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration=%BUILD_TYPE% ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:: -- build with nmake
::CD %PKGDIR%\zlib\win32
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR
::nmake /f makefile.msc
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR


::copy shared lib, dll
copy %PKGDIR%\zlib\contrib\vstudio\vc11\%PLATFORMX%\ZlibDll%BUILD_TYPE%\zlibwapi.lib %PKGDIR%\zlib\
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
copy %PKGDIR%\zlib\contrib\vstudio\vc11\%PLATFORMX%\ZlibDll%BUILD_TYPE%\zlibwapi.dll %PKGDIR%\zlib\
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::copy static lib
copy %PKGDIR%\zlib\contrib\vstudio\vc11\%PLATFORMX%\ZlibStat%BUILD_TYPE%\zlibstat.lib %PKGDIR%\zlib\zlib.lib
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


GOTO DONE


:NOBUILD
echo.
echo zlib will be built with/by libpng below
GOTO DONE


:ERROR
SET EL=%ERRORLEVEL%
ECHO ----------------- ERROR ZLIB --------------


:DONE
cd %ROOTDIR%
EXIT /b %EL%
