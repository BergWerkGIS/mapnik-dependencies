@echo off
SETLOCAL
SET EL=0
echo ------ osrm -----
:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO ERROR )
IF %TARGET_ARCH% EQU 32 ( echo "32bit not supported" && SET ERRORLEVEL=1 && GOTO ERROR )

SET BUILD_DEPS=0

::GOTO PREPARETESTS

:NEXT-ARG
IF "%1"=="" GOTO ARGS-DONE
IF /i "%1"=="builddeps" SET BUILD_DEPS=1 && GOTO ARG-OK

ECHO. && ECHO ------------------------------
ECHO Invalid argument "%1"
ECHO ------------------------------ && ECHO.

:ARG-OK
SHIFT
GOTO NEXT-ARG

:ARGS-DONE

ECHO BUILD_DEPS %BUILD_DEPS%

IF %BUILD_DEPS% EQU 0 GOTO BUILD_OSRM

echo ======== BUILDING AND PACKAGING ALL DEPS ================
cd %ROOTDIR%\scripts
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
CALL build_osrm_deps.bat
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::ZIP
SET ARCH=x64
if %TARGET_ARCH% EQU 32 SET ARCH=x86

for /f %%i in ('powershell Get-Date -format "yyyy.MM"') do set DATE_VERSION=%%i

SET PKGNAME=osrm-deps-win-%ARCH%-%TOOLS_VERSION%-%DATE_VERSION%.7z

CD %PKGDIR%\osrm-deps
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST %PKGNAME% DEL %PKGNAME%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

7z a -r -mx9 %PKGNAME% osrm-deps | %windir%\system32\FIND "ing archive"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO packaged to %PKGDIR%\osrm-deps\%PKGNAME%


:BUILD_OSRM
cd %PKGDIR%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

if NOT EXIST osrm-backend git clone https://github.com/Project-OSRM/osrm-backend osrm-backend
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

cd osrm-backend
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
git fetch
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
git pull
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST build ddt /Q build
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

mkdir build
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

cd build
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

SET OSRMDEPSDIR=%PKGDIR%\osrm-deps\osrm-deps
set PREFIX=%OSRMDEPSDIR%/libs
set BOOST_ROOT=%OSRMDEPSDIR%/boost
set TBB_INSTALL_DIR=%OSRMDEPSDIR%/tbb
set TBB_ARCH_PLATFORM=intel64/vc14

REM -DBoost_USE_STATIC_LIBS=ON ^

cmake .. ^
-G "Visual Studio 14 Win64" ^
-DBOOST_ROOT=%BOOST_ROOT% ^
-DBoost_ADDITIONAL_VERSIONS=1.%BOOST_VERSION% ^
-DBoost_USE_MULTITHREADED=ON ^
-DBoost_USE_STATIC_LIBS=ON ^
-DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
-DCMAKE_INSTALL_PREFIX=%PREFIX%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

REM /p:BuildInParallel=true ^
REM /m:%NUMBER_OF_PROCESSORS% ^
REM msbuild OSRM.sln /t:ALL_BUILD;rebuild ^

msbuild OSRM.sln ^
/p:Configuration=Release ^
/p:Platform=x64 ^
/p:BuildInParallel=true ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:PlatformToolset=%PLATFORM_TOOLSET% ^
/clp:Verbosity=normal ^
/nologo ^
/flp1:logfile=build_errors.txt;errorsonly ^
/flp2:logfile=build_warnings.txt;warningsonly
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:PREPARETESTS
ECHO getting ruby
IF EXIST %ROOTDIR%tmp-bin\ruby-2.2.2-x64-mingw32 GOTO RUNTESTS

cd %ROOTDIR%\tmp-bin
CALL %ROOTDIR%\scripts\download ruby-2.2.2-x64-mingw32.7z
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL 7z x -y ruby-2.2.2-x64-mingw32.7z | %windir%\system32\FIND "ing archive"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:RUNTESTS
ECHO TODO! running cucumber tests ...
SET PATH=%OSRMDEPSDIR%\libs\bin;%ROOTDIR%\tmp-bin\ruby-2.2.2-x64-mingw32\bin;%PKGDIR%\osrm-backend\build;%PATH%
::echo disk=%CD%\stxxl,1000,wincall > test/stxxl.txt
SET OSRM_TIMEOUT=200
SET STXXLCFG=stxxl.txt
CD %PKGDIR%\osrm-backend
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO TODO! calling cucumber
::CALL cucumber
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


ECHO =========== TRYING TO RUN OSRM ===============

CALL powershell %ROOTDIR%scripts\package_osrm.ps1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CD %PKGDIR%\osrm-release\osrm-release
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

COPY car.lua profile.lua
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO running datastructure-tests.exe ...
datastructure-tests.exe
ECHO ERRORLEVEL^: %ERRORLEVEL%
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO running algorithm-tests.exe ...
algorithm-tests.exe
ECHO ERRORLEVEL^: %ERRORLEVEL%
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR


SET TESTDATABASENAME=berlin-latest
SET TESTDATAPBF=berlin-latest.osm.pbf
SET TESTDATAOSRM=berlin-latest.osrm
ECHO downloading %TESTDATA%
CALL curl -O http://download.geofabrik.de/europe/germany/%TESTDATAPBF%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

osrm-extract %TESTDATAPBF%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

osrm-prepare %TESTDATAOSRM%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO ======== TODO^: TEST IF SERVER WORKS ===========
::osrm-routed %TESTDATAOSRM%
::IF %ERRORLEVEL% NEQ 0 GOTO ERROR
::http://localhost:5000/locate?loc=52.4224,13.333086
::http://localhost:5000/nearest?loc=52.4224,13.333086
::http://localhost:5000/viaroute?loc=52.503033,13.420526&loc=52.516582,13.429290&instructions=true

DEL %TESTDATABASENAME%*
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


ECHO ========= PACKAGING ===============

CD %PKGDIR%\osrm-backend
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

FOR /F "tokens=*" %%i in ('git describe') do SET GITVERSION=%%i
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

SET ARCH=x64
if %TARGET_ARCH% EQU 32 SET ARCH=x86

SET PKGNAME=osrm-release-%GITVERSION%-%ARCH%-win-%TOOLS_VERSION%.7z

cd %PKGDIR%\osrm-release
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST %PKGNAME% DEL %PKGNAME%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
IF EXIST %ROOTDIR%\bin\%PKGNAME% DEL %ROOTDIR%\bin\%PKGNAME%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

7z a -r -mx9 %PKGNAME% osrm-release | %windir%\system32\FIND "ing archive"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

COPY %PKGNAME% %ROOTDIR%\bin\
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO osrm-release copied to %ROOTDIR%\bin\%PKGNAME%
GOTO DONE


GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo ----------ERROR osrm --------------

:DONE
echo ----------DONE osrm --------------

cd %ROOTDIR%
EXIT /b %EL%
