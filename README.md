# Palo Alto PAN-OS Configuration Backup Script

This PowerShell script automates the retrieval of configuration files from Palo Alto Networks (PAN-OS) firewalls. It handles module installation, password encryption, and output cleaning in one go.

## Features
* **Auto-Provisioning:** Automatically installs the `Posh-SSH` module and required `NuGet` providers if missing.
* **Encrypted Passwords:** Uses Windows Data Protection API (DPAPI) so passwords aren't stored in plain text.
* **Clean Output:** Automatically strips CLI artifacts like [edit], --More--, and command echos to provide a clean set format config file.
* **Automated Workflow:** Sets the CLI pager off and output format to set before fetching the configuration.

## Setup & Usage
* **Change the output location for you backup:** Dont forget to chnage the path to your backup location in this variable
``` powershell
$BackupDir = "C:\PANOS_BACKUP_Config"
```
* **Generate Encrypted Password Strings:** Because the encryption is tied to your Windows user profile and machine, you must generate a unique string for each password on the machine where the script will run.
Run the following command in PowerShell and copy the output:
``` powershell
'YourActualPassword' | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
```

* **Update the Device Inventory:** Paste the long string from step 1 into the $Devices array within the script and add your username and managment ip adress
``` powershell
$Devices = @(
    @{ 
        Name = "PANOS_FW_1"
        IP   = "1.1.1.1"
        User = "YOUR_USERNAME_1"
        Pass = "PASTE_YOUR_PASSWORD_STRING_HERE"
    },
    @{ 
        Name = "PANOS_FW_2"
        IP   = "2.2.2.2"
        User = "YOUR_USERNAME_2"
        Pass = "PASTE_YOUR_PASSWORD_STRING_HERE"
    }
)
```

* **Run the Script:** Simply execute the script:
``` powershell
.\PANOS_BACKUP.ps1
```

## Troubleshooting
* **Ping Check:** Ensure you can ping the firewalls. If the script fails to connect, check the Management Permitted IP list on the Palo Alto device.
* **Module Issues:** If the script hangs on "Checking prerequisites," ensure you have internet access for the initial download of the Posh-SSH module.
* **New Machine:** If you move this script to a different computer, the Pass strings will become invalid. You will need to repeat Step 1 on the new machine.

