@echo off
SETLOCAL
SET EL=0
echo ------ MAPNIK -----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
if EXIST mapnik-%MAPNIKBRANCH% GOTO FETCHMAPNIK

ECHO cloning mapnik
git clone https://github.com/mapnik/mapnik mapnik-%MAPNIKBRANCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:FETCHMAPNIK
cd mapnik-%MAPNIKBRANCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO fetching mapnik
git fetch
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO checking out mapnik/%MAPNIKBRANCH%
git checkout %MAPNIKBRANCH%
ECHO ERRORLEVEL^: %ERRORLEVEL%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO pulling mapnik
git pull
ECHO ERRORLEVEL^: %ERRORLEVEL%
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::necessary for python bindings
if "%BOOSTADDRESSMODEL%"=="32" if EXIST %ROOTDIR%\tmp-bin\python2-x86-32 SET PATH=%ROOTDIR%\tmp-bin\python2-x86-32;%ROOTDIR%\tmp-bin\python2-x86-32\Scripts;%PATH%
if "%BOOSTADDRESSMODEL%"=="64" if EXIST %ROOTDIR%\tmp-bin\python2 SET PATH=%ROOTDIR%\tmp-bin\python2;%ROOTDIR%\tmp-bin\python2\Scripts;%PATH%

ECHO SUPERFASTBUILD^: %SUPERFASTBUILD%
IF NOT DEFINED SUPERFASTBUILD GOTO DEFAULT_BUILD
IF %SUPERFASTBUILD% NEQ 1 GOTO DEFAULT_BUILD
ECHO doing a SUPERFASTBUILD via AppVeyor build scripts
CALL scripts\build-local.bat "LOCAL_BUILD_DONT_SKIP_TESTS=%LOCAL_BUILD_DONT_SKIP_TESTS%" "FASTBUILD=%FASTBUILD%"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
GOTO DONE

:DEFAULT_BUILD
::git submodule update --init
git submodule update --init --recursive
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


:: python bindings
IF NOT DEFINED MAPNIKPYTHONBRANCH SET MAPNIKPYTHONBRANCH=master
IF NOT EXIST bindings\python git clone https://github.com/mapnik/python-mapnik.git bindings/python
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CD bindings\python & IF %ERRORLEVEL% NEQ 0 GOTO ERROR
git fetch & IF %ERRORLEVEL% NEQ 0 GOTO ERROR
git pull & IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO checking out mapnik python^: %MAPNIKPYTHONBRANCH%
git checkout %MAPNIKPYTHONBRANCH%
CD ..\.. & IF %ERRORLEVEL% NEQ 0 GOTO ERROR



REM patch -N -p1 < %PATCHES%\mapnik-test.exe-crash.diff || %SKIP_FAILED_PATCH%
REM IF %ERRORLEVEL% NEQ 0 GOTO ERROR
REM patch -N -p1 < %PATCHES%\mapnik-test.exe-crash-lock_guard.diff || %SKIP_FAILED_PATCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


::mapnik-gyp
if EXIST mapnik-gyp GOTO FETCHMAPNIKGYP

ECHO cloning mapnik-gyp
git clone https://github.com/mapnik/mapnik-gyp mapnik-gyp
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:FETCHMAPNIKGYP

cd mapnik-gyp
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO fetching mapnik-gyp
git fetch
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO checking out mapnik-gyp/%MAPNIKGYPBRANCH%
git checkout %MAPNIKGYPBRANCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO pulling mapnik-gyp
git pull
::don't check error level: if we are on a commit pull returns !=0
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR


ddt /Q mapnik-sdk
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::download prebuilt binary deps
IF %FASTBUILD% NEQ 1 GOTO FULLBUILD
SET BINDEPSPGK=mapnik-win-sdk-binary-deps-%TOOLS_VERSION%-%PLATFORMX%.7z
IF NOT EXIST %BINDEPSPGK% ECHO downloading binary deps package... && CALL %ROOTDIR%\scripts\download https://mapbox.s3.amazonaws.com/windows-builds/windows-build-deps/%BINDEPSPGK%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
IF NOT EXIST mapnik-sdk ECHO extracting binary deps package... && CALL 7z x -y %BINDEPSPGK% | %windir%\system32\FIND "ing archive"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


:FULLBUILD
ECHO building mapnik
SET TIME_BEFORE_BUILD=%TIME%
ECHO %TIME_BEFORE_BUILD%^: calling build.bat of mapnik-gyp ...
call build.bat
ECHO %TIME_BEFORE_BUILD%^: started build.bat of mapnik-gyp ...
ECHO %TIME%^: finished build.bat of mapnik-gyp
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:: jump to end, ignore PUBLISHMAPNIKSDK when %PACKAGEMAPNIK% EQU 0
IF %PACKAGEMAPNIK% EQU 0 GOTO DONE

:: PACKAGE MAPNIK
cd %PKGDIR%\mapnik-%MAPNIKBRANCH%\mapnik-gyp
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
CALL package.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR



IF %PUBLISHMAPNIKSDK% EQU 0 GOTO DONE

:: PUBLISH MAPNIK SDK
cd %PKGDIR%\mapnik-%MAPNIKBRANCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
FOR /F "tokens=*" %%i in ('git describe') do SET GITVERSION=%%i
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
SET SDK_PKG_NAME=mapnik-win-sdk-%GITVERSION%-%PLATFORMX%-%TOOLS_VERSION%.7z
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
cd %PKGDIR%\mapnik-%MAPNIKBRANCH%\mapnik-gyp
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
IF NOT EXIST %SDK_PKG_NAME% (ECHO SDK package not found %SDK_PKG_NAME% && GOTO ERROR)
CALL "C:\Program Files\Amazon\AWSCLI\aws.exe" s3 cp --acl public-read %SDK_PKG_NAME% s3://mapbox/mapnik-binaries/
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO upload of %SDK_PKG_NAME% completed

GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
ECHO ---------- ERROR windows-builds MAPNIK --------------

:DONE
ECHO ---------- DONE windows-builds MAPNIK --------------
cd %ROOTDIR%
EXIT /b %EL%
