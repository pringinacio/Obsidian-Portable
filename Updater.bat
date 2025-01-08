@echo off

cd /d %~dp0

set HERE=%~dp0
set HERE_DS=%HERE:\=\\%

set CURL=curl
set BUSYBOX="%HERE%App\Utils\busybox.exe"
set SZIP="%HERE%App\Utils\7za.exe"

:::::: PROXY

set PROXY=false
set HTTP-PROXY=http://127.0.0.1:3128
set HTTPS-PROXY=https://127.0.0.1:3128

::::::::::::::::::::

:::::: NETWORK CHECK

%BUSYBOX% wget -q --user-agent="Mozilla" --spider https://google.com

if "%ERRORLEVEL%" == "1" (
  echo Check Your Network Connection
  pause
  exit
)

::::::::::::::::::::

:::::: ARCH

if "%PROCESSOR_ARCHITECTURE%" == "x86" (
  set ARCH=6.7z
) else if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  set ARCH=4.7z
) else exit

:: set ARCH=6.7z
:: set ARCH=4.7z
:: set ARCH=2.7z

:: 6.7z x32
:: 4.7z x64
:: 2.7z arm64

::::::::::::::::::::

:::::: VERSION CHECK

if not exist "%WINDIR%\system32\wbem\wmic.exe" goto LATEST

wmic datafile where name='%HERE_DS%App\\Obsidian\\Obsidian.exe' get version | %BUSYBOX% tail -n2 ^
 | %BUSYBOX% rev ^
 | %BUSYBOX% cut -c 6- ^
 | %BUSYBOX% rev > current.txt

for /f %%V in ('more current.txt') do (set CURRENT=%%V)
echo Current: %CURRENT%

:LATEST

set LATEST_URL="https://github.com/obsidianmd/obsidian-releases/releases/latest"

%BUSYBOX% wget -q -O - %LATEST_URL% | %BUSYBOX% grep -o tag/v[0-9.]\+[0-9] | %BUSYBOX% cut -d "v" -f2 > latest.txt

for /f %%V in ('more latest.txt') do (set LATEST=%%V)
echo Latest: %LATEST%
echo:

if exist "current.txt" del "current.txt" > NUL
if exist "latest.txt" del "latest.txt" > NUL

if "%CURRENT%" == "%LATEST%" (
  echo You Have The Latest Version
  pause
  exit
) else goto PROCESS

::::::::::::::::::::

:PROCESS

:::::: RUNNING PROCESS CHECK

if not exist "%WINDIR%\system32\tasklist.exe" goto GET

for /f %%P in ('tasklist /NH /FI "IMAGENAME eq Obsidian.exe"') do if %%P == Obsidian.exe (
  echo Close Obsidian To Update
  pause
  exit
)

::::::::::::::::::::

:GET

:::::: GET LATEST VERSION

if exist "TMP" rmdir "TMP" /s /q
mkdir "TMP"

set OBSIDIAN="https://github.com/obsidianmd/obsidian-releases/releases/download/v%LATEST%/Obsidian-%LATEST%.exe"

if %PROXY% equ false %BUSYBOX% wget %OBSIDIAN% -O TMP\Obsidian-%LATEST%.exe

if %PROXY% equ true %CURL% -k -L -x %HTTP-PROXY% %OBSIDIAN% -o TMP\Obsidian.%LATEST%%ARCH%.exe

::::::::::::::::::::

:::::: UNPACKING

echo:
echo Unpacking

if exist "App\Obsidian" rmdir "App\Obsidian" /s /q

%SZIP% x -t# -aoa TMP\Obsidian-%LATEST%.exe -o"TMP" %ARCH% > NUL
%SZIP% x -aoa TMP\%ARCH% -o"App\Obsidian" > NUL

rmdir "TMP" /s /q

:::::: APP INFO

%BUSYBOX% sed -i "/Version/d" "%HERE%App\AppInfo\AppInfo.ini"
echo. >> "App\AppInfo\AppInfo.ini"
echo [Version] >> "App\AppInfo\AppInfo.ini"
echo DisplayVersion=%LATEST% >> "App\AppInfo\AppInfo.ini"

::::::::::::::::::::

echo:
echo Done

pause
