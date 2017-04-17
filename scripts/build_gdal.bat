@echo off
SETLOCAL
SET EL=0
ECHO ~~~~~~~~~~~~~~~~~~~ %~f0 ~~~~~~~~~~~~~~~~~~~

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%

SET VS2014_CTP4_DETECTED=0
CALL %ROOTDIR%\scripts\check-cl.bat 19.00.22129.1
IF %ERRORLEVEL% EQU 0 SET VS2014_CTP4_DETECTED=1

IF %VS2014_CTP4_DETECTED% EQU 1 (
	SET ODBC_SUPPORTED=0
) ELSE (
	SET ODBC_SUPPORTED=1
)

ECHO GDAL_VERSION^: %GDAL_VERSION%
ECHO VS2014_CTP4_DETECTED^: %VS2014_CTP4_DETECTED%
ECHO ODBC_SUPPORTED^: %ODBC_SUPPORTED%

if EXIST gdal echo found extracted sources ... && GOTO SRCALREADYEXTRACTED

CALL %ROOTDIR%\scripts\download gdal-%GDAL_VERSION%.tar.gz
IF ERRORLEVEL 1 GOTO ERROR

echo extracting ...
CALL bsdtar xfz gdal-%GDAL_VERSION%.tar.gz
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
rename gdal-%GDAL_VERSION% gdal
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
cd %PKGDIR%\gdal
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF %VS2014_CTP4_DETECTED% EQU 0 patch -N -p1 < %PATCHES%\gdal-200-VS2015RC1.diff
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


:SRCALREADYEXTRACTED

cd %PKGDIR%\gdal
IF ERRORLEVEL 1 GOTO ERROR


::echo When compiling 64bit download libexpat dev packages from http://www.gtk.org/download/win64.php
::echo Also un-comment WIN64=YES in nmake.opt -> can be passed as argument, see below

::https://trac.osgeo.org/gdal/wiki/BuildingOnWindows
::see basic options

:: !!! BUILD FIRST and then do 'devinstall'!!!
SET EXPAT_DIR="%PKGDIR%\expat"
SET EXPAT_INCLUDE=-I%EXPAT_DIR%\lib
SET EXPAT_LIB=%EXPAT_DIR%\win32\bin\%BUILD_TYPE%\libexpat.lib
SET TIFF_INC="-I%PKGDIR%\libtiff\libtiff"
SET TIFF_LIB="%PKGDIR%\libtiff\libtiff\libtiff_i.lib"
SET TIFF_OPTS=/DBIGTIFF_SUPPORT /DCHUNKY_STRIP_READ_SUPPORT=1 /DDEFER_STRILE_LOAD=1
SET JPEGDIR="%PKGDIR%\libjpegturbo"
SET SQLITE_INC=-I%PKGDIR%\sqlite
SET SQLITE_LIB=%PKGDIR%\sqlite\sqlite3.lib
SET DEBUG=1
SET WITH_PDB=1
::MSSQL support
::SET ODBC_SUPPORTED=1
IF "%PLATFORMX%"=="x64" SET WIN64=YES

SET CL=/MP

ECHO cleaning .....
CALL nmake /F makefile.vc clean
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO building ....
CALL nmake /A /F makefile.vc
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


::odbccp32.lib(dllload.obj) : error LNK2019: unresolved external symbol __vsnwprintf_s referenced in function _StringCchPrintfW
::gdal111.dll : fatal error LNK1120: 1 unresolved externals

::ECHO upgrading solution
::CALL devenv.exe /upgrade makegdal10.sln
::IF ERRORLEVEL 1 GOTO ERROR

::ECHO building ...
::CALL msbuild makegdal10.sln /t:Rebuild  /p:Configuration="Release" /p:Platform=Win32
::IF ERRORLEVEL 1 GOTO ERROR


GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
ECHO ~~~~~~~~~~~~~~~~~~~ ERROR %~f0 ~~~~~~~~~~~~~~~~~~~
ECHO ERRORLEVEL^: %EL%

:DONE
ECHO ~~~~~~~~~~~~~~~~~~~ DONE %~f0 ~~~~~~~~~~~~~~~~~~~

cd %ROOTDIR%
EXIT /b %EL%
