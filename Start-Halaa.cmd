@echo off
setlocal
cd /d "%~dp0server"
where node >nul 2>nul
if errorlevel 1 (
  echo Install Node.js 22.13 or later, then open this file again.
  pause
  exit /b 1
)
if not defined PORT set PORT=3000
echo Open http://localhost:%PORT% in your browser.
echo On a phone on the same Wi-Fi, open http://YOUR-PC-IPv4:%PORT%.
node app.mjs
if errorlevel 1 pause

