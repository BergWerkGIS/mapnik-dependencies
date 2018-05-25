@echo off

:::::::::::::: USAGE
:: see bottom of this file

:::::::::::::: OVERRIDABLE PARAMETERS
SET TOOLS_VERSION=14.0
SET TARGET_ARCH=64
SET MAPNIKBRANCH=master
SET BUILDMAPNIKPYTHON=0
SET MAPNIKGYPBRANCH=master
SET MAPNIKPYTHONBRANCH=master
SET NODEMAPNIKBRANCH=master
SET SKIP_FAILED_PATCH=false
SET FASTBUILD=1
SET RUNCODEANALYSIS=0
SET SHAREDTMPBIN=
SET SHAREDPKGSRC=
SET MAPNIK_BUILD_TESTS=1
SET PACKAGEDEPS=0
SET PACKAGEMAPNIK=1
SET PUBLISHMAPNIKSDK=0
SET PUBLISHNODEMAPNIK=0
SET PACKAGEDEBUGSYMBOLS=0
SET VERBOSE=0
SET IGNOREFAILEDTESTS=0
SET IGNOREFAILEDVISUALTESTS=0
::local meaning, built by these scripts
SET PREFER_LOCAL_NODE_EXE=1
::node-mapnik: use local mapnik sdk or download sdk defined for AppVeyor
SET USE_LOCAL_MAPNIK_SDK=1
SET BUNDLE_RUNTIME=0

::try to stay in sync with https://github.com/mapnik/mapnik/blob/master/bootstrap.sh
SET BOOST_VERSION=64
SET ICU_VERSION=56.1
SET ICU_VERSION2=56_1
SET WEBP_VERSION=0.5.1
SET JPEG_VERSION=8d
SET LIBJPEGTURBO_VERSION=1.5.0
SET FREETYPE_VERSION=2.7
SET FREETYPE_VERSION_FILE=27
SET ZLIB_VERSION=1.2.8
SET BZIP2_VERSION=1.0.6
SET LIBPNG_VERSION=1.6.24
SET LIBPNG_VERSION_FILE=16
SET POSTGRESQL_VERSION=9.4.5
SET TIFF_VERSION=4.0.6
SET PIXMAN_VERSION=0.34.0
SET CAIRO_VERSION=1.14.6
::SET LIBXML2_VERSION=2.9.2
SET PROJ_VERSION=4.9.2
SET PROJ_GRIDS_VERSION=1.5
SET EXPAT_VERSION=2.2.0
SET GDAL_VERSION=2.1.1
SET GDAL_VERSION_FILE=201
SET SQLITE_VERSION=3140100
SET SPATIAL_LITE_VERSION=4.2.0
SET PROTOBUF_VERSION=2.6.1
SET SPARSEHASH_VERSION=2.0.3
SET HARFBUZZ_VERSION=1.3.0
SET GEOS_VERSION=3.4.2
SET PYTHON_VERSION=2.7.8
SET NODE_VERSION=0.12.7
SET BUILD_STATIC=0
SET TBB_VERSION=43_20150209oss


:::::::::::::: OVERRIDE PARAMETERS
:NEXT-ARG

IF '%1'=='' GOTO ARGS-DONE
ECHO setting %1
SET %1
SHIFT
GOTO NEXT-ARG

:ARGS-DONE


::BAIL OUT IF DEBUG or VS2013
IF DEFINED BUILD_TYPE IF NOT "%BUILD_TYPE%"=="Release" (SET BUILD_TYPE=) && ECHO only Release builds supported! && SET EL=1 && GOTO ERROR
IF DEFINED TOOLS_VERSION IF NOT "%TOOLS_VERSION%"=="14.0" IF NOT "%TOOLS_VERSION%"=="15.0" (SET TOOLS_VERSION=) && ECHO only Visual Studio 2015^/2017 supported! && SET EL=1 && GOTO ERROR


:::::::::::::: FIXED PARAMETERS
SET BUILD_TYPE=Release
IF NOT DEFINED TOOLS_VERSION SET TOOLS_VERSION=14.0
SET RUNTIME_VERSION=vcredist-VS2015



::::::::::::::: DO STUFF

IF NOT EXIST C:\Python27 ( ECHO C:\Python27 not found && GOTO ERROR )


IF EXIST "C:\Program Files (x86)\Git\bin" SET PATH=C:\Program Files (x86)\Git\bin;%PATH%
IF EXIST "C:\Program Files\Git\usr\bin" SET PATH=C:\Program Files\Git\usr\bin;%PATH%
IF EXIST "C:\Program Files\Git\bin" SET PATH=C:\Program Files\Git\bin;%PATH%
WHERE git >NUL
IF %ERRORLEVEL% NEQ 0 (ECHO git not found && GOTO ERROR)
WHERE curl >NUL
IF %ERRORLEVEL% NEQ 0 (ECHO curl not found, is git installed && GOTO ERROR)


if "%TARGET_ARCH%" == "32" (
  SET BUILDPLATFORM=Win32
  SET BOOSTADDRESSMODEL=32
  SET WEBP_PLATFORM=x86
  SET PLATFORMX=x86
)

if "%TARGET_ARCH%" == "64" (
  SET BUILDPLATFORM=x64
  SET BOOSTADDRESSMODEL=64
  SET WEBP_PLATFORM=x64
  SET PLATFORMX=x64
)

SET current_script_dir=%~dp0
SET ROOTDIR=%current_script_dir%
SET PKGDIR=%ROOTDIR%packages
IF NOT EXIST %PKGDIR% MKDIR %PKGDIR%
SET PATCHES=%ROOTDIR%patches
IF NOT EXIST %PATCHES% MKDIR %PATCHES%

::TODO: see what we can use from mysysgit
::wget cmake
SET PATH=C:\Windows\System32\WindowsPowershell\v1.0;%PATH%
SET PATH=C:\Python27;%PATH%
SET PATH=C:\Python27\Scripts;%PATH%
SET PATH=%CD%\tmp-bin\cmake-3.1.0-win32-x86\bin;%PATH%
SET PATH=%CD%\tmp-bin\nasm-2.11.08;%PATH%
SET PATH=%CD%\tmp-bin\gnu-win-tools;%PATH%
SET PATH=%CD%\tmp-bin\ragel\%PLATFORMX%;%PATH%
::always use 7z x64, 32bit version cannot handle size of mapnik + PDBs
SET PATH=%CD%\tmp-bin\7zip\x64;%PATH%
SET PATH=%CD%\tmp-bin\ddt\%PLATFORMX%;%PATH%
SET PATH=%CD%\tmp-bin\scriptcs;%PATH%
SET PATH=%CD%\tmp-bin;%PATH%
::set path to make.exe at last.
::make.exe that comes with gnu-win-tools cannot compile cairo
SET PATH=%CD%\tmp-bin\make;%PATH%

IF "%TOOLS_VERSION%"=="15.0" GOTO SETUPVS2017

ECHO ------- setting up for VS 2015
SET MSVC_VER=1900
SET PLATFORM_TOOLSET=v140
IF "%TARGET_ARCH%" == "32" CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64_x86
IF "%TARGET_ARCH%" == "64" CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
IF %ERRORLEVEL% NEQ 0 ECHO error calling vcvarsall.bat && GOTO ERROR
GOTO VSSETUPFINISHED

:SETUPVS2017
ECHO ------- setting up for VS 2017
REM test for VS2017 is _MSC_VER > 1900
REM VS2017 has '19xx' to indicate binary-compatible toolsets with VS2015
SET MSVC_VER=1911
SET PLATFORM_TOOLSET=v141
ECHO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ECHO TODO: figure out how to get correct path
ECHO       to VS2017 install
ECHO       ^%VS150COMNTOOLS^% has the right path
ECHO       only *AFTER* 'VsDevCmd.bat' has run
ECHO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
IF "%TARGET_ARCH%" == "32" ECHO setting up for 32bit build && CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat" -arch=x86 -host_arch=amd64 -app_platform=Desktop
IF "%TARGET_ARCH%" == "64" ECHO setting up for 64bit build && CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat" -arch=amd64 -host_arch=amd64 -app_platform=Desktop
IF %ERRORLEVEL% NEQ 0 ECHO error calling VsDevCmd.bat && GOTO ERROR


:VSSETUPFINISHED


WHERE msbuild >NUL
IF %ERRORLEVEL% NEQ 0 ECHO msbuild not found && GOTO ERROR

CD %ROOTDIR%

IF NOT EXIST tmp-bin (
  CALL curl -k -O https://mapbox.s3.amazonaws.com/windows-builds/windows-build-deps/windows-builds-tmp-bin.exe
  CALL windows-builds-tmp-bin.exe -y -o"."
)
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

python setuptools-available.py
IF %ERRORLEVEL% NEQ 0 (
  ECHO Please install setuptools for python!
  ECHO see https://pypi.python.org/pypi/setuptools#installation-instructions
  GOTO ERROR
)

if NOT EXIST C:\Python27\Scripts\aws (
  echo. && echo getting aws-cli
  ddt /Q aws-cli
  git clone --depth=1 https://github.com/aws/aws-cli.git
  cd aws-cli
  python setup.py install
  cd ..
)


:: need PACKAGEMAPNIK for PUBLISHMAPNIKSDK to work
IF %PUBLISHMAPNIKSDK% NEQ 0 IF %PACKAGEMAPNIK% EQU 0 GOTO PUBLISHMAPNIKSDKERROR

IF %PUBLISHMAPNIKSDK% NEQ 0 GOTO CHECKAWS
IF %PUBLISHNODEMAPNIK% NEQ 0 GOTO CHECKAWS

GOTO CHECKPOWERSHELL


:CHECKAWS
ECHO.
ECHO ------------checking for AWS-CLI ---------
ECHO checking for AWS_ACCESS_KEY_ID
IF "%AWS_ACCESS_KEY_ID%" == "" GOTO AWSNOKEYS
ECHO checking for AWS_SECRET_ACCESS_KEY
IF "%AWS_SECRET_ACCESS_KEY%" == "" GOTO AWSNOKEYS
ECHO AWS keys found
CALL "C:\Program Files\Amazon\AWSCLI\aws.exe" --version
::9009 -> "<CMD> is not recognized as an internal or external command, operable program or batch file."
IF %ERRORLEVEL% EQU 9009 GOTO AWSNOTAVAILABLE
IF %ERRORLEVEL% NEQ 0 GOTO AWSUNKNOWNERROR
ECHO AWS-CLI OK
ECHO.


:CHECKPOWERSHELL
ECHO.
ECHO ------------ checking for Powershell ------------
ECHO Powershell version^:
powershell $PSVersionTable.PSVersion
IF %ERRORLEVEL% NEQ 0 GOTO PSNOTAVAILABLE

FOR /F "tokens=*" %%i in ('powershell Get-ExecutionPolicy') do SET PSPOLICY=%%i
ECHO Powershell execution policy^: %PSPOLICY%
IF NOT "%PSPOLICY%"=="Unrestricted" powershell Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force
IF %ERRORLEVEL% NEQ 0 GOTO PSPOLICYERROR
FOR /F "tokens=*" %%i in ('powershell Get-ExecutionPolicy') do SET PSPOLICY=%%i
ECHO Powershell execution policy now is^: %PSPOLICY%

powershell Get-PSDrive -PSProvider FileSystem

::install scriptcs
powershell .\scripts\get-scriptcs.ps1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
WHERE scriptcs >NUL
IF %ERRORLEVEL% NEQ 0 ECHO scriptcs not found && GOTO ERROR

GOTO DONE

:USAGE
ECHO usage:
ECHO settings.bat ^<target_arch^> ^<tools_version^> ^<build_type^>
ECHO settings.bat 32^|64 12^|14 Release^|Debug
EXIT /b 1

GOTO DONE

:ERROR
ECHO !!!!!!!! ===== ERROR ==== !!!!!!!!
ECHO builds cannot be run unless settings.bat finished successfully
CD %ROOTDIR%
EXIT /b 1

:DONE

ECHO. && ECHO ------ PARAMETERS ------
ECHO TARGET_ARCH^: %TARGET_ARCH%
ECHO TOOLS_VERSION^: %TOOLS_VERSION%
ECHO BUILD_TYPE^: %BUILD_TYPE%
ECHO FASTBUILD^: %FASTBUILD%
ECHO SUPERFASTBUILD^: %SUPERFASTBUILD%
ECHO SKIP_FAILED_PATCH^: %SKIP_FAILED_PATCH%
ECHO.
ECHO MAPNIKBRANCH^: %MAPNIKBRANCH%
ECHO MAPNIKGYPBRANCH^: %MAPNIKGYPBRANCH%
ECHO NODEMAPNIKBRANCH^: %NODEMAPNIKBRANCH%
ECHO.
ECHO PACKAGEMAPNIK^: %PACKAGEMAPNIK%
ECHO PACKAGEDEBUGSYMBOLS^: %PACKAGEDEBUGSYMBOLS%
ECHO PUBLISHMAPNIKSDK^: %PUBLISHMAPNIKSDK%
ECHO PUBLISHNODEMAPNIK^: %PUBLISHNODEMAPNIK%


echo. && echo building within %current_script_dir% && ECHO. &&ECHO.

echo ------ USAGE ------
echo Calling "scripts\build" will run with above default parameters.
echo Parameters can be overriden, see top of source of this file for
echo overridable parameters. && ECHO.
echo Override like this (parameters MUST be quoted!)^: && ECHO.
echo settings "MAPNIKBRANCH=mybranch" "GDAL_VERSION=2.0.1" "SKIP_FAILED_PATCH=true"
echo.


GOTO THENEND


:PUBLISHMAPNIKSDKERROR
ECHO.
ECHO !!!
ECHO parameter mismatch!!
ECHO PUBLISHMAPNIKSDK=1 needs PACKAGEMAPNIK=1
ECHO !!!
ECHO.
GOTO ERROR


:AWSNOKEYS
ECHO.
ECHO !!!
ECHO AWS keys not set!!
ECHO check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS
ECHO !!!
ECHO.
GOTO ERROR


:AWSUNKNOWNERROR
ECHO.
ECHO !!!
ECHO unexpected error calling AWS CLI!!
ECHO is AWS CLI installed
ECHO !!!
ECHO.
GOTO ERROR

:AWSNOTAVAILABLE
ECHO.
ECHO !!!
ECHO AWS CLI not found!!
ECHO check installation and availabilty on PATH
ECHO !!!
ECHO.
GOTO ERROR


:PSNOTAVAILABLE
ECHO.
ECHO !!!!
ECHO Powershell is not available!!!
ECHO check PATH and if it is installed
ECHO !!!!
ECHO.
GOTO ERROR

:PSPOLICYERROR
ECHO.
ECHO !!!!
ECHO Could not set Powershell execution policy to 'Unrestricted'
ECHO !!!!
ECHO.
GOTO ERROR



:THENEND
