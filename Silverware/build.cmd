@echo off
setlocal
:: Auto Plant Bali
echo Auto Plant Bali (Silverware) Menu:
echo 1. Brushed Motor
echo 2. Brushless Motor
SET /P M=Type 1 or 2 then press ENTER:
IF %M%==1 goto Opt1
IF %M%==2 goto Opt2

:Opt1
color 0C
goto Build
:Opt2
color 0A
goto Build

:Build
set WaitForLicenseTimeout=60
set BuildAttemptsMax=10

set "ProjectFileName=silverware.uvprojx"
set "ProjectPath=%CD%\"
set "Compiler=C:\Keil_v5\UV4\UV4.exe"
set "OutFolder=Objects\"
:: ======================
:: Do not edit below this line
set BuildAttempt=0

pushd %ProjectPath%

:PerformBuild
echo:
echo:Auto Plant Bali Compiler.
echo:
echo:Performing Keil Build...

if exist build.log                   del build.log
if exist %OutFolder%*.build_log.htm  del %OutFolder%*.build_log.htm
if exist %ProjectPath%apb_silverware.bin  del %ProjectPath%apb_silverware.bin
if exist %ProjectPath%apb_silverware.hex  del %ProjectPath%apb_silverware.hex

start /wait %Compiler% -j0 -b %ProjectFileName% -o build.log
set ReportedError=%ERRORLEVEL%

:: Scan build.log to determine if the license is locked.
find /c "Error: *** All Flex licenses are in use! ***" build.log  >nul
if %errorlevel% equ 0 (
    set /a BuildAttempt=%BuildAttempt% + 1 
    echo:Error: *** All Flex licenses are in use!
    if %BuildAttempt% equ %BuildAttemptsMax% goto NoLicenseAvailable
    echo:Retrying ^(%BuildAttempt% of %BuildAttemptsMax%^) in %WaitForLicenseTimeout% seconds
    waitfor SignalNeverComming /T %WaitForLicenseTimeout% >nul 2>&1
    goto PerformBuild
) 
:: Scan alternative build.log to determine if the license is locked.
find /c "Failed to check out a license" %OutFolder%*.build_log.htm >nul
if %errorlevel% equ 0 (
    set /a BuildAttempt=%BuildAttempt% + 1 
    echo:Error: Failed to check out a license
    if %BuildAttempt% equ %BuildAttemptsMax% goto NoLicenseAvailable
    echo:Retrying ^(%BuildAttempt% of %BuildAttemptsMax%^) in %WaitForLicenseTimeout% seconds
    waitfor SignalNeverComming /T %WaitForLicenseTimeout% >nul 2>&1
    goto PerformBuild
)
goto NoLicenseProblem


:NoLicenseAvailable
echo:Error: After %BuildAttempt% attempts, the Flex license still appear to be unavailable. Failing the build!
echo:
popd
exit /b 1

:NoLicenseProblem
:: Parse exit codes
set KnownErrors=0 1 2 3 11 12 13 15 20 41

echo:Kiel compiler exited with error code %ReportedError%

for %%a in (%KnownErrors%) do (
   if [%ReportedError%] equ [%%a] goto Error%ReportedError%
)
goto UnknownError

:Error0
   echo Compilation successful
   goto ExitButContinueJob

:Error1
   echo Warnings were found
   goto ExitButContinueJob

:Error2 
   echo Errors were found
   goto ExitCritical

:Error3
   echo Error 3 = Fatal Errors
   goto ExitCritical

:Error11
   echo Error 11 = Cannot open project file for writing
   goto ExitCritical

:Error12
   echo Error 12 = Device with given name in not found in database
   goto ExitCritical

:Error13
   echo Error 13 = Error writing project file
   goto ExitCritical

:Error15
   echo Error 15 = Error reading import XML file
   goto ExitCritical

:Error20
   echo Error 20 = Can not convert the project file.
   goto ExitCritical

:Error41
   echo Error 41 = Can not create the logfile requested using the -l switch.
   goto ExitCritical

:UnknownError
   echo Error %ReportedError% = Unknown error 
   goto ExitCritical

:ExitCritical
echo:
if [%ReportedError%] neq 0 exit /b %ReportedError% 

:ExitButContinueJob
echo: Moving Binary File...
if exist %ProjectPath%%OutFolder%apb_silverware.bin  move %ProjectPath%%OutFolder%apb_silverware.bin %ProjectPath%
if exist %ProjectPath%%OutFolder%apb_silverware.hex  move %ProjectPath%%OutFolder%apb_silverware.hex %ProjectPath%
popd
exit /b 0