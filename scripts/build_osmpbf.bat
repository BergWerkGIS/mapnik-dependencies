@echo off
SETLOCAL
SET EL=0
echo ------ OSMPBF, OSM-binary -----
:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%

if NOT EXIST OSM-binary (
	git clone https://github.com/scrosby/OSM-binary.git
)
cd OSM-binary
IF ERRORLEVEL 1 GOTO ERROR
git fetch
IF ERRORLEVEL 1 GOTO ERROR
git pull
IF ERRORLEVEL 1 GOTO ERROR

::libprotobuf.lib
::libprotobuf-lite.lib

IF %BUILDPLATFORM% EQU x64 (
	SET PROTOC=%PKGDIR%\protobuf\vsprojects\%BUILDPLATFORM%\%BUILD_TYPE%\protoc.exe
	SET PROTOLIB=%PKGDIR%\protobuf\vsprojects\%BUILDPLATFORM%\%BUILD_TYPE%\libprotobuf-lite.lib
) ELSE (
	SET PROTOC=%PKGDIR%\protobuf\vsprojects\%BUILD_TYPE%\protoc.exe
	SET PROTOLIB=%PKGDIR%\protobuf\vsprojects\%BUILD_TYPE%\libprotobuf-lite.lib
)

SET CMAKE_CMD=cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_INSTALL_PREFIX=%PKGDIR%\OSM-binary\deploy ^
-DPROTOBUF_PROTOC_EXECUTABLE=%PROTOC% ^
-DPROTOBUF_LIBRARY=%PROTOLIB% ^
-DProtobuf_INCLUDE_DIR=%PKGDIR%\protobuf\src

ECHO about to run cmake:
ECHO %CMAKE_CMD%

%CMAKE_CMD%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

nmake src install
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo ----------ERROR OSMPBF --------------

:DONE
echo ----------DONE OSMPBF --------------

cd %ROOTDIR%
EXIT /b %EL%
