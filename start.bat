@echo off
cd /d %~dp0

:: Set node path
set NODE_PATH=nodejs\windows
set NODE=%~dp0%NODE_PATH%\node.exe

:: Install service
%NODE% node_modules\node-windows\bin\node-windows install n8n-service.js

:: Start service
%NODE% node_modules\node-windows\bin\node-windows start n8n-service.js
