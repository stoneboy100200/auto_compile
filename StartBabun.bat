@echo off
setlocal enableextensions enabledelayedexpansion

echo *******************Start babun********************
echo Start time: %date% %time%
set BAT_PATH=%~dp0
echo BAT_PATH: %BAT_PATH%
set HOME_PATH=%HOME%
echo HOME_PATH: %HOME_PATH%

:BEGIN
if defined HOME_PATH (
  set MINTTY=%HOME_PATH%\..\..\bin\mintty.exe
) else (
  set MINTTY=%USERPROFILE%\.babun\cygwin\bin\mintty.exe
)
echo MINTTY: %MINTTY%

if exist %MINTTY% (
  goto :RUN
) else (
  goto :NOTFOUND
)

:NOTFOUND
echo [Error]Invalid path: %MINTTY%
EXIT /b 255

:RUN
"%MINTTY%" -h always -e /bin/sh -l -c 'source d:/NavRepoVS2013/StartCompileNaviCore.sh d:/NavRepoVS2013/nincg3 d:/NavRepoVS2013/navi_development'

echo End time: %date% %time%
echo *******************End********************