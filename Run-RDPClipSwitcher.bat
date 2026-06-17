@echo off
:: 以管理员身份启动菜单脚本
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"%~dp0RDPClipSwitcher.ps1\"'"
