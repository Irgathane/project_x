@echo off
cd /d "%~dp0"
rem Expected layout: vkquake.exe and id1\ live one folder up.
set "VK=..\vkquake.exe"
if not exist "%VK%" set "VK=vkquake"
start "" "%VK%" -game slipgate +map starter
