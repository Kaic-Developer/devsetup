#Requires -Version 5.1

<#
.SYNOPSIS
    Kaic DevSetup - Windows Development Environment Bootstrapper

.DESCRIPTION
    Prepara automaticamente uma máquina Windows para desenvolvimento:
    - WSL 2
    - Virtual Machine Platform
    - Hyper-V (quando disponível/necessário)
    - Ubuntu
    - Git
    - Visual Studio Code
    - Docker Desktop

.AUTHOR
    Kaic Leonardo

.GITHUB
    https://github.com/Kaic-Developer

.LINKEDIN
    https://www.linkedin.com/in/kaic-leonardo-087347345/

.NOTES
    Projeto pessoal para automatização de ambiente de desenvolvimento.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURAÇÃO
# ============================================================

$Config = @{
    UbuntuDistribution = "Ubuntu"

    Packages = @(
        @{
            Name = "Git"
            Id   = "Git.Git"
        },
        @{
            Name = "Visual Studio Code"
            Id   = "Microsoft.VisualStudioCode"
        },
        @{
            Name = "Docker Desktop"
            Id   = "Docker.DockerDesktop"
        }
    )
}

$Script:RestartRequired = $false
$Script:Failures = @()

# ============================================================
# INTERFACE
# ============================================================

function Write-Header {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                       KAIC DEVSETUP" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Windows Development Environment Bootstrapper"
    Write-Host ""
    Write-Host " Autor    : Kaic Leonardo"
    Write-Host " GitHub   : https://github.com/Kaic-Developer"
    Write-Host " LinkedIn : https://www.linkedin.com/in/kaic-leonardo-087347345/"
    Write-Host ""
}

function Write-Step {
    param([string]$Message)

    Write-Host "[....] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)

    Write-Host "[ OK ] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-WarningMessage {
    param([string]$Message)

    Write-Host "[AVISO] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Failure {
    param([string]$Message)

    Write-Host "[ERRO] " -ForegroundColor Red -NoNewline
    Write-Host $Message

    $Script:Failures += $Message
}

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
}

# ============================================================
# ADMINISTRADOR
# ============================================================

function Test-IsAdministrator {

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = New-Object `
        Security.Principal.WindowsPrincipal($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Request-Administrator {

    if (Test-IsAdministrator) {
        return
    }

    Write-Host "Solicitando permissao de Administrador..."

    $Arguments = @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        "`"$PSCommandPath`""
    )

    Start-Process `
        -FilePath "powershell.exe" `
        -Verb RunAs `
        -ArgumentList $Arguments

    exit
}

# ============================================================
# WINDOWS OPTIONAL FEATURES
# ============================================================

function Get-FeatureState {

    param(
        [Parameter(Mandatory)]
        [string]$FeatureName
    )

    try {

        return Get-WindowsOptionalFeature `
            -Online `
            -FeatureName $FeatureName `
            -ErrorAction Stop

    }
    catch {

        return $null
    }
}

function Enable-FeatureIfNeeded {

    param(
        [Parameter(Mandatory)]
        [string]$FeatureName,

        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    $Feature = Get-FeatureState -FeatureName $FeatureName

    if ($null -eq $Feature) {

        Write-WarningMessage "$DisplayName nao esta disponivel nesta edicao do Windows."
        return
    }

    if ($Feature.State -eq "Enabled") {

        Write-Success "$DisplayName habilitado."
        return
    }

    Write-Step "Habilitando $DisplayName..."

    try {

        $Result = Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName $FeatureName `
            -All `
            -NoRestart `
            -ErrorAction Stop

        Write-Success "$DisplayName habilitado."

        if ($Result.RestartNeeded) {
            $Script:RestartRequired = $true
        }

    }
    catch {

        Write-Failure "Falha ao habilitar $DisplayName`: $($_.Exception.Message)"
    }
}

# ============================================================
# WINGET
# ============================================================

function Test-Winget {

    return $null -ne (
        Get-Command winget.exe -ErrorAction SilentlyContinue
    )
}

function Test-WingetPackage {

    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    try {

        $Output = & winget.exe list `
            --id $Id `
            --exact `
            --accept-source-agreements `
            --disable-interactivity 2>$null

        return ($LASTEXITCODE -eq 0)

    }
    catch {

        return $false
    }
}

function Install-WingetPackage {

    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Id
    )

    if (Test-WingetPackage -Id $Id) {

        Write-Success "$Name ja esta instalado."
        return
    }

    Write-Step "Instalando $Name..."

    try {

        & winget.exe install `
            --id $Id `
            --exact `
            --source winget `
            --accept-package-agreements `
            --accept-source-agreements `
            --disable-interactivity

        if ($LASTEXITCODE -eq 0) {

            Write-Success "$Name instalado."

        }
        else {

            Write-Failure "$Name retornou codigo $LASTEXITCODE durante a instalacao."
        }

    }
    catch {

        Write-Failure "Falha ao instalar $Name`: $($_.Exception.Message)"
    }
}

# ============================================================
# WSL
# ============================================================

function Test-WSLCommand {

    return $null -ne (
        Get-Command wsl.exe -ErrorAction SilentlyContinue
    )
}

function Get-WSLDistros {

    if (-not (Test-WSLCommand)) {
        return @()
    }

    try {

        # O uso de --list --quiet pode produzir caracteres NUL dependendo
        # da combinação PowerShell/WSL. Removemos esses caracteres antes
        # de comparar os nomes das distribuições.

        $RawOutput = (& wsl.exe --list --quiet 2>$null) -join "`n"

        if ([string]::IsNullOrWhiteSpace($RawOutput)) {
            return @()
        }

        $CleanOutput = $RawOutput -replace "`0", ""

        return @(
            $CleanOutput `
                -split "`r?`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
        )

    }
    catch {

        return @()
    }
}

function Test-UbuntuInstalled {

    $Distros = Get-WSLDistros

    foreach ($Distro in $Distros) {

        if ($Distro -match "^Ubuntu($|-.*)") {
            return $true
        }
    }

    return $false
}

function Install-Ubuntu {

    if (-not (Test-WSLCommand)) {

        Write-WarningMessage "WSL ainda nao esta disponivel. Reinicie o Windows primeiro."
        return
    }

    if (Test-UbuntuInstalled) {

        Write-Success "Ubuntu ja esta instalado."
        return
    }

    if ($Script:RestartRequired) {

        Write-WarningMessage "Ubuntu sera instalado depois do reinicio."
        return
    }

    Write-Step "Instalando Ubuntu..."

    try {

        & wsl.exe --install `
            --distribution $Config.UbuntuDistribution `
            --no-launch

        if ($LASTEXITCODE -eq 0) {

            Write-Success "Ubuntu instalado."

        }
        else {

            Write-Failure "A instalacao do Ubuntu retornou codigo $LASTEXITCODE."
        }

    }
    catch {

        Write-Failure "Falha ao instalar Ubuntu: $($_.Exception.Message)"
    }
}

function Configure-WSL {

    if (-not (Test-WSLCommand)) {
        return
    }

    try {

        Write-Step "Definindo WSL 2 como versao padrao..."

        & wsl.exe --set-default-version 2

        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL 2 definido como padrao."
        }

    }
    catch {

        Write-WarningMessage "Nao foi possivel definir WSL 2 agora."
    }
}

# ============================================================
# DOCKER
# ============================================================

function Test-DockerDesktopInstalled {

    if (Test-WingetPackage -Id "Docker.DockerDesktop") {
        return $true
    }

    $Paths = @(

        "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe",
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    )

    foreach ($Path in $Paths) {

        if (Test-Path $Path) {
            return $true
        }
    }

    return $false
}

# ============================================================
# DIAGNÓSTICO
# ============================================================

function Show-SystemInformation {

    Write-Section "SISTEMA"

    try {

        $OS = Get-CimInstance Win32_OperatingSystem

        Write-Success $OS.Caption
        Write-Success "Windows $($OS.Version)"

    }
    catch {

        Write-WarningMessage "Nao foi possivel obter informacoes do Windows."
    }

    if ([Environment]::Is64BitOperatingSystem) {

        Write-Success "Sistema operacional 64 bits."

    }
    else {

        Write-Failure "Windows 32 bits nao e adequado para este ambiente."
    }

    try {

        $Computer = Get-CimInstance Win32_ComputerSystem

        if ($Computer.HypervisorPresent) {

            Write-Success "Hipervisor detectado."

        }
        else {

            Write-WarningMessage "Hipervisor ainda nao foi detectado."
        }

    }
    catch {

        Write-WarningMessage "Nao foi possivel consultar o hipervisor."
    }
}

# ============================================================
# INSTALAÇÃO
# ============================================================

function Install-WindowsInfrastructure {

    Write-Section "INFRAESTRUTURA WINDOWS"

    Enable-FeatureIfNeeded `
        -FeatureName "VirtualMachinePlatform" `
        -DisplayName "Virtual Machine Platform"

    Enable-FeatureIfNeeded `
        -FeatureName "Microsoft-Windows-Subsystem-Linux" `
        -DisplayName "Windows Subsystem for Linux"

    # Hyper-V nao existe em todas as edicoes do Windows.
    # Quando disponivel, habilitamos os componentes.
    $HyperV = Get-FeatureState `
        -FeatureName "Microsoft-Hyper-V"

    if ($null -ne $HyperV) {

        Enable-FeatureIfNeeded `
            -FeatureName "Microsoft-Hyper-V" `
            -DisplayName "Hyper-V"
    }
}

function Install-DeveloperTools {

    Write-Section "FERRAMENTAS"

    if (-not (Test-Winget)) {

        Write-Failure "winget nao foi encontrado."

        Write-WarningMessage `
            "Instale/atualize o App Installer da Microsoft e execute novamente."

        return
    }

    Write-Success "winget disponivel."

    foreach ($Package in $Config.Packages) {

        Install-WingetPackage `
            -Name $Package.Name `
            -Id $Package.Id
    }
}

# ============================================================
# VALIDAÇÃO FINAL
# ============================================================

function Show-FinalStatus {

    Write-Section "VALIDACAO"

    # WSL

    if (Test-WSLCommand) {

        Write-Success "WSL disponivel."

    }
    else {

        Write-WarningMessage "WSL ainda nao esta disponivel."
    }

    # Ubuntu

    if (Test-UbuntuInstalled) {

        Write-Success "Ubuntu detectado corretamente."

    }
    elseif ($Script:RestartRequired) {

        Write-WarningMessage "Ubuntu aguardando reinicio/configuracao."

    }
    else {

        Write-WarningMessage "Ubuntu nao foi detectado."
    }

    # Git

    if (
        (Get-Command git.exe -ErrorAction SilentlyContinue) -or
        (Test-WingetPackage -Id "Git.Git")
    ) {

        Write-Success "Git instalado."

    }
    else {

        Write-WarningMessage "Git nao detectado."
    }

    # VS Code

    if (
        (Get-Command code.cmd -ErrorAction SilentlyContinue) -or
        (Test-WingetPackage -Id "Microsoft.VisualStudioCode")
    ) {

        Write-Success "Visual Studio Code instalado."

    }
    else {

        Write-WarningMessage "Visual Studio Code nao detectado."
    }

    # Docker

    if (Test-DockerDesktopInstalled) {

        Write-Success "Docker Desktop instalado."

    }
    else {

        Write-WarningMessage "Docker Desktop nao detectado."
    }

    # vmcompute

    $VMCompute = Get-Service `
        -Name vmcompute `
        -ErrorAction SilentlyContinue

    if ($VMCompute) {

        Write-Success "vmcompute disponivel."

    }
    elseif ($Script:RestartRequired) {

        Write-WarningMessage "vmcompute pode exigir reinicio."

    }
    else {

        Write-WarningMessage "vmcompute nao detectado."
    }
}

# ============================================================
# RESULTADO
# ============================================================

function Finish-Setup {

    Write-Section "RESULTADO"

    if ($Script:Failures.Count -gt 0) {

        Write-Host ""
        Write-Host "Ocorreram $($Script:Failures.Count) erro(s):" `
            -ForegroundColor Red

        foreach ($Failure in $Script:Failures) {

            Write-Host " - $Failure" -ForegroundColor Red
        }

        Write-Host ""
    }

    if ($Script:RestartRequired) {

        Write-Host ""
        Write-Host "REINICIO NECESSARIO" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Alguns recursos do Windows foram habilitados."
        Write-Host ""
        Write-Host "Reinicie o computador e execute novamente:"
        Write-Host ""
        Write-Host "    INSTALAR.bat" -ForegroundColor Cyan
        Write-Host ""

    }
    elseif ($Script:Failures.Count -eq 0) {

        Write-Host ""
        Write-Host "============================================================" `
            -ForegroundColor Green

        Write-Host "              AMBIENTE DEV CONFIGURADO" `
            -ForegroundColor Green

        Write-Host "============================================================" `
            -ForegroundColor Green

        Write-Host ""
        Write-Host "Se o Ubuntu foi instalado agora, abra-o uma vez"
        Write-Host "para criar seu usuario e senha Linux."
        Write-Host ""
        Write-Host "Depois abra o Docker Desktop."
        Write-Host ""
    }

    Write-Host "------------------------------------------------------------"
    Write-Host " Kaic DevSetup"
    Write-Host " GitHub:   https://github.com/Kaic-Developer"
    Write-Host " LinkedIn: https://www.linkedin.com/in/kaic-leonardo-087347345/"
    Write-Host "------------------------------------------------------------"
    Write-Host ""

    Read-Host "Pressione ENTER para sair"
}

# ============================================================
# MAIN
# ============================================================

function Main {

    Request-Administrator

    Write-Header

    Show-SystemInformation

    Install-WindowsInfrastructure

    Configure-WSL

    Install-DeveloperTools

    Write-Section "UBUNTU"

    Install-Ubuntu

    Show-FinalStatus

    Finish-Setup
}

Main