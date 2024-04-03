@echo off
title Remotesteuerung WTS

query session /vm
echo.
echo.

set /p session-id=Session-ID (q zum Beenden): 
if %session-id%==q exit
 
echo. 
echo Connecting to session #%session-id%:
mstsc /shadow:%session-id% /control
