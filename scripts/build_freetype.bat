@echo off
SETLOCAL
SET EL=0

echo ----- freetype-----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL %ROOTDIR%\scripts\download freetype-%FREETYPE_VERSION%.tar.bz2
IF ERRORLEVEL 1 GOTO ERROR

if EXIST freetype (
  echo found extracted sources
)

if NOT EXIST freetype (
  echo extracting
  CALL bsdtar xfz freetype-%FREETYPE_VERSION%.tar.bz2
  rename freetype-%FREETYPE_VERSION% freetype
  IF ERRORLEVEL 1 GOTO ERROR
)

cd freetype
IF ERRORLEVEL 1 GOTO ERROR

if "%TARGET_ARCH%"=="64" (
  echo.
  ECHO "IF building x64 add platform to solution manually!"
  ECHO.
)

::DebugInformationFormat
::OldStyle = /Z7 (within file)
::ProgramDatabase = /Zi (pdb)
::EditAndContinue = /ZI
REM ::/p:DebugInformation=EditAndContinue ^


ECHO building ...
msbuild ^
.\builds\windows\vc2010\freetype.sln ^
/p:ForceImportBeforeCppTargets=%ROOTDIR%\scripts\force-debug-information-for-sln.props ^
/nologo ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration=%BUILD_TYPE% ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
IF ERRORLEVEL 1 GOTO ERROR

ECHO build ok

IF %BUILDPLATFORM% EQU x64 (
  IF %BUILD_TYPE% EQU Release (
    CALL copy /Y objs\vc2010\x64\freetype%FREETYPE_VERSION_FILE%.lib freetype.lib
    IF ERRORLEVEL 1 GOTO ERROR
  ) ELSE (
    CALL copy /Y objs\vc2010\x64\freetype%FREETYPE_VERSION_FILE%D.lib freetype.lib
    IF ERRORLEVEL 1 GOTO ERROR
    CALL copy /Y objs\vc2010\x64\freetype%FREETYPE_VERSION_FILE%D.pdb freetype.pdb
    IF ERRORLEVEL 1 GOTO ERROR
  )
) ELSE (
  IF %BUILD_TYPE% EQU Release (
    CALL copy /Y objs\vc2010\Win32\freetype%FREETYPE_VERSION_FILE%.lib freetype.lib
    IF ERRORLEVEL 1 GOTO ERROR
  ) ELSE (
    CALL copy /Y objs\win32\vc2010\freetype%FREETYPE_VERSION_FILE%_D.lib freetype.lib
    IF ERRORLEVEL 1 GOTO ERROR
    CALL copy /Y objs\debug\freetype.pdb freetype.pdb
    IF ERRORLEVEL 1 GOTO ERROR
  )
)

GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo -------------FREETYPE ERROR -----------------

:DONE
cd %ROOTDIR%
EXIT /b %EL%
