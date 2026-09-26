@echo off
title DevSetup - Preparando ambiente

cd /d "%~dp0"

echo ========================================
echo  DEV SETUP
echo ========================================
echo.
echo Iniciando configuracao...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-dev.ps1"

if errorlevel 1 (
    echo.
    echo [ERRO] O DevSetup encontrou um problema.
    pause
)