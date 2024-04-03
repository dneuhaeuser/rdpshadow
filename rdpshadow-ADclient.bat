@echo off
title Remotesteuerung AD-Client

set /p termserver=Host/IP: 

for /f "tokens=3" %%a in ('query session /server:%termserver%  ^| findstr /i console') do (
  echo. 
  echo Connecting to session #%%a on %termserver%:
  mstsc /v:%termserver% /shadow:%%a /control
)
