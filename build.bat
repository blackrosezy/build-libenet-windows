@echo off
setlocal EnableDelayedExpansion 

set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%

REM Check if Visual Studio 2013 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 12.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2013"
	goto setup_env
)

REM Check if Visual Studio 2012 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 11.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2012"
	goto setup_env
)

REM Check if Visual Studio 2010 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 10.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2010"
	goto setup_env
)

REM Check if Visual Studio 2008 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 9.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2008"
	goto setup_env
)

REM Check if Visual Studio 2005 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 8"
if exist %MSVCDIR% (
	set COMPILER_VER="2005"
	goto setup_env
) 

REM Check if Visual Studio 6 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio\VC98"
if exist %MSVCDIR% (
	set COMPILER_VER="6"
	goto setup_env
) 

echo No compiler : Microsoft Visual Studio (6, 2005, 2008, 2010, 2012 or 2013) is not installed.
goto end

:setup_env

echo Setting up environment
if %COMPILER_VER% == "6" (
	call %MSVCDIR%\Bin\VCVARS32.BAT
	goto begin
)

call %MSVCDIR%\VC\vcvarsall.bat x86

:begin

REM Setup path to helper bin
set ROOT_DIR="%CD%"
set RM="%CD%\bin\unxutils\rm.exe"
set CP="%CD%\bin\unxutils\cp.exe"
set MKDIR="%CD%\bin\unxutils\mkdir.exe"
set SEVEN_ZIP="%CD%\bin\7-zip\7za.exe"
set WGET="%CD%\bin\unxutils\wget.exe"
set XIDEL="%CD%\bin\xidel\xidel.exe"

REM Housekeeping
%RM% -rf tmp_*
%RM% -rf third-party
%RM% -rf enet.zip
%RM% -rf build_*.txt


REM Download latest enet and rename to enet.zip
echo Downloading latest enet..
%WGET% "https://github.com/lsalzman/enet/archive/master.zip" -O enet.zip

REM Extract downloaded zip file to tmp_libenet
%SEVEN_ZIP% x enet.zip -y -otmp_libenet | FIND /V "ing  " | FIND /V "Igor Pavlov"

cd tmp_libenet\enet-master

if %COMPILER_VER% == "6" goto vc6
if %COMPILER_VER% == "2005" goto vc2005
if %COMPILER_VER% == "2008" goto vc2008
if %COMPILER_VER% == "2010" goto vc2010
if %COMPILER_VER% == "2012" goto vc2012
if %COMPILER_VER% == "2013" goto vc2013


:vc6
REM Build!
msdev enet.dsp /MAKE ALL /build
goto copy_files

:vc2005
:vc2008
REM Upgrade libenet project file to compatible installed Visual Studio version
vcbuild /upgrade enet.dsp

REM Build!
vcbuild enet.vcproj
goto copy_files

:vc2010
:vc2012
:vc2013
REM Upgrade libenet project file to compatible installed Visual Studio version
vcupgrade enet.dsp

REM Build!
msbuild enet.vcxproj /p:Configuration="Debug" /t:Rebuild
msbuild enet.vcxproj /p:Configuration="Release" /t:Rebuild
goto copy_files

:copy_files

REM Copy compiled .*lib files in lib-release folder to third-party folder
%MKDIR% -p %ROOT_DIR%\third-party\libenet\lib\lib-release
%CP% Release\*.lib %ROOT_DIR%\third-party\libenet\lib\lib-release

REM Copy compiled .*lib files in lib-debug folder to third-party folder
%MKDIR% -p %ROOT_DIR%\third-party\libenet\lib\lib-debug
%CP% Debug\*.lib %ROOT_DIR%\third-party\libenet\lib\lib-debug


REM Copy include folder to third-party folder
%CP% -rf include %ROOT_DIR%\third-party\libenet

REM Copy license information to third-party folder
%CP% LICENSE %ROOT_DIR%\third-party\libenet\

REM Cleanup temporary file/folders
cd %ROOT_DIR%
%RM% -rf tmp_*

:end
exit /b
