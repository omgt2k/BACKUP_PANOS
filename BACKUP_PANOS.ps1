# 0. Ensure Environment is ready
# This installs the NuGet provider silently if it's missing
if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
}

# This checks if Posh-SSH is installed; if not, it installs it
if (!(Get-Module -ListAvailable -Name Posh-SSH)) {
    Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber
}

Import-Module Posh-SSH -ErrorAction Stop

# 1. Configuration
$BackupDir = "C:\PANOS_BACKUP_Config"
$Date = Get-Date -Format "yyyyMMdd"

# Create directory if it doesn't exist
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir
}

# 2. Device Inventory
$Devices = @(
    @{ 
        Name = "PA460A"
        IP   = "46.46.46.46"
        User = "YOUR_USERNAME"
        Pass = "PASTE_YOUR_STRING_HERE"
    },
    @{ 
        Name = "PA540"
        IP   = "54.54.54.54"
        User = "YOUR_USERNAME"
        Pass = "PASTE_YOUR_STRING_HERE"
    }
)

# 3. Execution Loop
foreach ($Device in $Devices) {
    Write-Host "`n--- Connecting to $($Device.Name) ($($Device.IP)) ---" -ForegroundColor Cyan
    $SshSession = $null
    # Convert the encrypted hex string back into a SecureString object
    $SecurePass = $Device.Pass | ConvertTo-SecureString
    try {
        # Now create the credential object
        $Creds = New-Object System.Management.Automation.PSCredential($Device.User, $SecurePass)
        
        # Establish Session
        $SshSession = New-SSHSession -ComputerName $Device.IP -Credential $Creds -AcceptKey -ErrorAction Stop
        $Stream = New-SSHShellStream -Index $SshSession.SessionId
        
        # Expect Logic Helper
        function Wait-ForPrompt {
            param($Stream, $Prompt, $TimeoutMs = 30000)
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $buffer = ""
            while ($timer.ElapsedMilliseconds -lt $TimeoutMs) {
                $chunk = $Stream.Read()
                if ($chunk) { 
                    $buffer += $chunk 
                    # Safety check: if the firewall still tries to page, send a spacebar
                    if ($buffer -match "--More--") { $Stream.Write(" ") }
                    if ($buffer -match $Prompt) { return $buffer }
                }
                Start-Sleep -Milliseconds 200
            }
            throw "Timed out waiting for prompt matching '$Prompt'"
        }

        # Setup (Operational Mode)
        Wait-ForPrompt -Stream $Stream -Prompt "@" | Out-Null
        Write-Host "Disabling CLI paging..."
        $Stream.WriteLine("set cli pager off")
        Wait-ForPrompt -Stream $Stream -Prompt "@" | Out-Null
        Write-Host "Setting CLI format..."
        $Stream.WriteLine("set cli config-output-format set")
        Wait-ForPrompt -Stream $Stream -Prompt "@" | Out-Null

        # Enter Config Mode
        Write-Host "Entering configuration mode..."
        $Stream.WriteLine("configure")
        Wait-ForPrompt -Stream $Stream -Prompt "#" | Out-Null

        # Show Config
        Write-Host "Fetching configuration (this will now scroll automatically)..." -NoNewline
        $Stream.WriteLine("show")
        
        $RawConfig = Wait-ForPrompt -Stream $Stream -Prompt "#" -TimeoutMs 120000
        Write-Host " Done." -ForegroundColor Gray
        
        # Save and Clean
        if ($RawConfig) {
            $FilePath = Join-Path $BackupDir "$($Device.Name)-$Date.txt"
            $Lines = $RawConfig -split "`r`n"
            $CleanedLines = $Lines | Where-Object { 
                $_ -notmatch "^show\s*$" -and 
                $_ -notmatch "#\s*$" -and
                $_ -notmatch "\[edit\]" -and
                $_ -notmatch "Entering configuration mode" -and
                $_.Trim().Length -gt 0 
            }

            $CleanedLines | Out-File -FilePath $FilePath -Encoding utf8
            Write-Host "SUCCESS: Saved to $FilePath" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        if ($SshSession) { Remove-SSHSession -SSHSession $SshSession | Out-Null }
    }
}
