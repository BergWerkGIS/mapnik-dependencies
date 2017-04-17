@echo off
SETLOCAL
SET EL=0

ECHO ~~~~~~~~~~~~~~~~~~~ %~f0 ~~~~~~~~~~~~~~~~~~~

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL %ROOTDIR%\scripts\download freetype-%FREETYPE_VERSION%.tar.bz2
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST freetype ECHO found extracted sources && GOTO SRC_EXTRACTED


ECHO extracting && bsdtar xfz freetype-%FREETYPE_VERSION%.tar.bz2
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO renaming dir && rename freetype-%FREETYPE_VERSION% freetype
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CD %PKGDIR%\freetype
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

IF EXIST %PATCHES%\freetype-v%FREETYPE_VERSION%.diff ECHO applying %PATCHES%\freetype-v%FREETYPE_VERSION%.diff && patch -N -p1 < %PATCHES%/freetype-v%FREETYPE_VERSION%.diff || %SKIP_FAILED_PATCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
IF EXIST %PATCHES%\freetype-v%FREETYPE_VERSION%.diff ECHO patch applied
IF NOT EXIST %PATCHES%\freetype-v%FREETYPE_VERSION%.diff ECHO no v%FREETYPE_VERSION% patch found


:SRC_EXTRACTED

ECHO changing into freetype && CD %PKGDIR%\freetype
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO building freetype ...
msbuild ^
.\builds\windows\vc2010\freetype.sln ^
/p:ForceImportBeforeCppTargets=%ROOTDIR%\scripts\force-debug-information-for-sln.props ^
/nologo ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration="%BUILD_TYPE%" ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO freetype v%FREETYPE_VERSION% build successful

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
    CALL copy /Y objs\vc2010\Win32\freetype%FREETYPE_VERSION_FILE%D.lib freetype.lib
    IF ERRORLEVEL 1 GOTO ERROR
    CALL copy /Y objs\vc2010\Win32\freetype%FREETYPE_VERSION_FILE%D.pdb freetype.pdb
    IF ERRORLEVEL 1 GOTO ERROR
  )
)

GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
ECHO ~~~~~~~~~~~~~~~~~~~ ERROR %~f0 ~~~~~~~~~~~~~~~~~~~

:DONE
ECHO ~~~~~~~~~~~~~~~~~~~ DONE %~f0 ~~~~~~~~~~~~~~~~~~~
cd %ROOTDIR%
EXIT /b %EL%
