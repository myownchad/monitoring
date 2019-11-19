@Echo OFF
SETLOCAL EnableDelayedExpansion

REM =======[ Settings ]========================================================================================
set "IP=4.2.2.2"             // IP or Address
set "LOG=%IP%.log"              // Log File name and Location, name equal %IP%.log
set "LTime=1000"                 // If OutResult Exceeds this time in ms it will turn the screen RED
set "ErrorSensitivity=10"       // How many error/timeout it should wait till it notify the user on connection loosing
set "VoiceAlarm=on"             // Set it to Off or any thing else if you don't want any alarm
set "LoggingMode=no"            // if yes it will log the events, any thing else will not log

REM =======[ DON'T MODIFY ANY THING FROM DOWN HERE ]============================================================
set bar=
for /L %%i in (1,1,66) do set bar=!bar!@
set lastColor=0

SET "Flag="                   // Used for checking to see if it will call the voice function or not, DON'T CHANGE
SET "ErrorCount=0"            // Used for calculating the time out times before reporting it, DON'T CHANGE
mode con: lines=3

Rem On The First Run
IF "!Flag!" == "" (
   CALL :Voice "Connecting"   // Only on the first run
   SET "Flag=On"
)

:Loop
SET "LatencyTime="            // To Reset The Latency Time, without it won't detect loosing the connection, DON'T CHANGE

rem Ping the IP, get the time
for /F "delims=" %%a in ('ping "%IP%" -n 1 ^| findstr /C:"Reply from"') do (
   set "line=%%a"
   for /F "tokens=7 delims== " %%b in ("%%a") do set LatencyTime=%%b
)

Rem Check Connectivity and Alart The user
IF "%latencytime:~-2%" == "ms" ( 
   IF "!Flag!" == "On" (
      IF /I "%VoiceAlarm%" == "on" (
         CALL :Voice "Connection Established"
      )
      SET "Flag=Off"
   )
   REM Here we Reste the error count to zero
   SET "ErrorCount=0"
) Else (
   IF "!Flag!" == "Off" (
      SET /A ErrorCount = ErrorCount + 1
      Rem This to prevent any fals alarm, like on single time outs.
      IF "!ErrorCount!" GTR "%ErrorSensitivity%" (
         IF /I "%VoiceAlarm%" == "on" (
            CALL :Voice "Connection Lost"
         )
         SET "Flag=On"
      )
   )
)

Rem If the time changed: update log and screen
if /i "%LoggingMode%" == "yes" echo %date% %time% - %line%>> "%LOG%"
set /A barLen=%LatencyTime:~0,-2% * 66 / LTime
if !barLen! lss 66 (
  set color=0A
) else (
  set color=0C
  set barLen=66
)
for %%l in (!barLen!) do set newBar=!bar:~0,%%l!
title latency: !LatencyTime!
CLS
echo/
Rem This is to prevent displaying an empty full bar when Latency Time is empty
IF NOT "%LatencyTime%" == "" (
   echo Time: %LatencyTime%  !newBar!
)
IF !color! neq %lastColor% (
  color !color!
  set lastColor=!color!
)

goto :Loop

Exit /B

:Voice <high latencytime>
rem Create the VBScript, if not exist
(   FOR /F "tokens=1*" %%a IN (' findstr "^:Voice: " ^< "%~F0" ') DO Echo.%%b    )>"%TEMP%\Voice.vbs"
Cscript //nologo "%TEMP%\Voice.vbs" "%~1"
GOTO :EOF
:Voice: Dim message, sapi
:Voice: Set sapi=CreateObject("sapi.spvoice")
:Voice: sapi.Speak chr(34) & WScript.Arguments(0) & chr(34)

Rem LEAVE EMPTY LINE BELOW THIS ONE
