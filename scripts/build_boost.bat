@echo off
SETLOCAL
SET EL=0
ECHO ~~~~~~~~~~~~~~~~~~~ %~f0 ~~~~~~~~~~~~~~~~~~~

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL %ROOTDIR%\scripts\download boost_1_%BOOST_VERSION%_0.tar.bz2
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST boost ECHO boost already extracted - check if current version is right && GOTO BOOST_EXTRACTED

ECHO extracting boost
CALL bsdtar xzf %PKGDIR%/boost_1_%BOOST_VERSION%_0.tar.bz2
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
rename boost_1_%BOOST_VERSION%_0 boost
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
SET BOOST_PATCH=%PATCHES%\boost-1_%BOOST_VERSION%.diff
IF NOT EXIST %BOOST_PATCH% ECHO no patch found && GOTO BOOST_EXTRACTED
cd %PKGDIR%\boost
ECHO applying %BOOST_PATCH%
patch -N -p1 < %BOOST_PATCH% || %SKIP_FAILED_PATCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:BOOST_EXTRACTED

cd %PKGDIR%\boost
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::ohhh, how i LOVE commandline. CANNOT set path when using parentheses e.g. IF EXIST xyz ( SET PATH=bla;%PATH% )
::%PATH% would get evaluated as a command and bail out of BAT with unexpected ERROR
::e.g. "\Microsoft was unexpected at this time."
IF "%BOOSTADDRESSMODEL%"=="32" IF EXIST %ROOTDIR%\tmp-bin\python2-x86-32 SET PATH=%ROOTDIR%\tmp-bin\python2-x86-32;%PATH%
IF "%BOOSTADDRESSMODEL%"=="32" IF NOT EXIST %ROOTDIR%\tmp-bin\python2-x86-32 ECHO no Python in tmp-bin && SET ERRORLEVEL=1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
IF "%BOOSTADDRESSMODEL%"=="64" IF EXIST %ROOTDIR%\tmp-bin\python2 SET PATH=%ROOTDIR%\tmp-bin\python2;%PATH%
IF "%BOOSTADDRESSMODEL%"=="64" IF NOT EXIST %ROOTDIR%\tmp-bin\python2 ECHO no Python in tmp-bin && SET ERRORLEVEL=1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

SET BOOSTARCHITECTURE=x86
if "%BOOSTADDRESSMODEL%"=="64" (
  SET BOOSTARCHITECTURE=ia64
  IF %BUILD_TYPE% EQU Release (
    SET ICU_LINK="/LIBPATH:%PKGDIR%\icu\lib64 icuuc.lib icuin.lib icudt.lib"
  ) ELSE (
    SET ICU_LINK="/LIBPATH:%PKGDIR%\icu\lib64 icuucd.lib icuind.lib icudtd.lib"
  )
  echo !!!!!!!!!
  echo USING x86 COMMANDPROMPT!!!!!!!!
  REM ::http://www.boost.org/boost-build2/doc/html/bbv2/reference/tools.html#v2.reference.tools.compiler.msvc.64
  REM ::If you provide a path to the compiler explicitly, provide the path to the 32-bit compiler. If you try to specify the path to any of 64-bit
  echo !!!!!!!!

  ::use x86 command prompt
  if "%TOOLS_VERSION%" == "12.0" (
    CALL "C:/Program Files (x86)/Microsoft Visual Studio 12.0/VC/vcvarsall.bat" x86
  )
  if "%TOOLS_VERSION%" == "14.0" (
    CALL "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/vcvarsall.bat" x86
  )
  if "%TOOLS_VERSION%" == "15.0" (
    REM CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat" -arch=x86 -host_arch=amd64 -app_platform=Desktop
  )
) ELSE (
  IF %BUILD_TYPE% EQU Release (
    SET ICU_LINK="/LIBPATH:%PKGDIR%\icu\lib icuuc.lib icuin.lib icudt.lib"
  ) ELSE (
    SET ICU_LINK="/LIBPATH:%PKGDIR%\icu\lib icuucd.lib icuind.lib icudtd.lib"
  )
)

IF "%TARGET_ARCH%"=="32" SET PATH=%PKGDIR%\icu\bin;%PATH%
IF "%TARGET_ARCH%"=="64" SET PATH=%PKGDIR%\icu\bin64;%PATH%
SET INCLUDE=%PKGDIR%\icu\include;%INCLUDE%
SET ICU_DATA=%PKGDIR%\icu\source\data\in\
ECHO ICU_LINK %ICU_LINK%

::NOTE: you cannot have both pythons installed otherwise it appears bjam will still find the 64 bit one

IF EXIST b2.exe GOTO ALREADY_BOOTSTRAPPED

SET BOOST_TOOLS_VERSION=%TOOLS_VERSION%
IF "%TOOLS_VERSION%"=="15.0" SET BOOST_TOOLS_VERSION=14.1
ECHO calling bootstrap bat
CALL bootstrap.bat --with-toolset=msvc-%BOOST_TOOLS_VERSION%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF NOT "%TOOLS_VERSION%"=="15.0" GOTO ALREADY_BOOTSTRAPPED
ECHO using VS2017^: writing custom 'project-config.jam' to make boost find VS2017's cl.exe
scriptcs %ROOTDIR%\scripts\vs2017-write-boost-project-config-jam.csx
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


:ALREADY_BOOTSTRAPPED

::VS2010/MSBuild 10: toolset=msvc-10.0
::VS2012/MSBuild 11: toolset=msvc-11.0
::VS2013/MSBuild 12: toolset=msvc-12.0
::64bit: http://stackoverflow.com/a/2326485

:: HINT: problems with icu configure check?
:: cat bin.v2/config.log to see problems

::CALL b2 toolset=msvc-12.0 --clean

IF %BUILD_TYPE% EQU Release (
  SET BOOST_BUILD_TYPE=release
) ELSE (
  REM debug-store=database (to create pdb files) does not work for static libs
  REM debug-store=object directly embeds the symbol information into the .lib file
  SET BOOST_BUILD_TYPE=variant=debug debug-symbols=on debug-store=object
)

ECHO BOOST_BUILD_TYPE %BOOST_BUILD_TYPE%

REM link=shared ^

SET BOOST_BUILD_CMD=b2 -j%NUMBER_OF_PROCESSORS% ^
-a ^
-d2 %BOOST_BUILD_TYPE% stage ^
--build-type=minimal ^
toolset=msvc-%BOOST_TOOLS_VERSION% -q ^
runtime-link=shared ^
link=static ^
address-model=%BOOSTADDRESSMODEL% ^
architecture=%BOOSTARCHITECTURE% ^
--with-iostreams ^
--with-test ^
--with-thread ^
--with-filesystem ^
--with-date_time ^
--with-system ^
--with-program_options ^
--with-regex ^
--disable-filesystem2 ^
-sHAVE_ICU=1 ^
-sICU_PATH=%PKGDIR%\icu ^
-sICU_LINK=%ICU_LINK% ^
-sZLIB_SOURCE=%PKGDIR%\zlib ^
-sBUILD=boost_unit_test_framework

ECHO 1st build step:
ECHO %BOOST_BUILD_CMD%

%BOOST_BUILD_CMD%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:: build boost_python now
:: we do this separately because
:: we want to dynamically link python

SET BOOST_BUILD_CMD=b2 -j%NUMBER_OF_PROCESSORS% ^
  -a ^
  -d2 %BOOST_BUILD_TYPE% stage ^
  --build-type=minimal toolset=msvc-%BOOST_TOOLS_VERSION% -q ^
  runtime-link=shared link=shared ^
  address-model=%BOOSTADDRESSMODEL% ^
  --with-python python=2.7

ECHO 2nd build step:
ECHO %BOOST_BUILD_CMD%

IF "%TOOLS_VERSION%"=="15.0" ECHO !!!!! SKIPPING 2nd build step 'boost_python' - does not work yet with VS2017 && GOTO SKIPPED_PYTHON_BUILD

%BOOST_BUILD_CMD%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:SKIPPED_PYTHON_BUILD


GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
ECHO ~~~~~~~~~~~~~~~~~~~ ERROR %~f0 ~~~~~~~~~~~~~~~~~~~
ECHO ERRORLEVEL^: %EL%

:DONE

::reset x64 command prompt
if "%BOOSTADDRESSMODEL%"=="64" (
  if "%TOOLS_VERSION%" == "12.0" (
    CALL "C:/Program Files (x86)/Microsoft Visual Studio 12.0/VC/vcvarsall.bat" amd64
  )
  if "%TOOLS_VERSION%" == "14.0" (
    CALL "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/vcvarsall.bat" amd64
  )
)

cd %ROOTDIR%
EXIT /b %EL%
