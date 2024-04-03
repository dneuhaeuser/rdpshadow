@echo off
title Remotesteuerung REMOTE-Client

set /p termserver=Host/IP: 
set /p termuser=Domain\User: 

runas /netonly /user:%termuser% "cmd /C query session /server:%termserver% >c:\temp\1rdp.txt"

ping localhost -n 4 >nul
echo.
type c:\temp\1rdp.txt

for /f "tokens=3" %%a in ('type c:\temp\1rdp.txt ^| findstr /i console') do (
  echo. 
  echo Connecting to session #%%a on %termserver%:
  mstsc /v:%termserver% /shadow:%%a /control /prompt
)

del c:\temp\1rdp.txt
