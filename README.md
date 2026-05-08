# Palo Alto PAN-OS Configuration Backup Tools

This repository provides two automated solutions for retrieving configuration files from Palo Alto Networks (PAN-OS) firewalls. Both scripts handle output cleaning and format setting to provide a ready-to-use set format backup.

## Choose Your Flavor

| Feature      | PowerShell Version                   | Python Version                         |
| :----------- | :----------------------------------- | :------------------------------------- |
| Filename     | BACKUP_PANOS.ps1                     | BACKUP_PANOS.py                        |
| Best For     | Native Windows environments          | Cross-platform (Windows, Linux, macOS) |
| Security     | Windows DPAPI (tied to user profile) | .env Environment variables (Portable)  |
| Dependencies | Posh-SSH module                      | Netmiko, python-dotenv                 |

## Option 1: Python (Cross-Platform)

The Python version is ideal for DevOps pipelines, Linux servers, or developers working across different operating systems.

### Features
* **Environment-Based Secrets:** Uses a .env file to keep credentials out of the code.
* **Smart Cleaning:** Removes CLI headers, footers, and [edit] markers using list comprehension.
* **Auto-Paging:** Leverages Netmiko to handle CLI paging automatically.

### Setup & Usage
* **Install Requirements:**
``` shell
pip install netmiko python-dotenv
```
* **Configure Secrets:**
The script looks for specific environment variables based on the device names. Create a .env file in the root directory and map your firewall credentials like this:
```
# Device: FW1
FW1_USER=FW1Username
FW1_PASS=FW1YourSecretPassword
# Device: FW2
FW2_USER=FW2Username
FW2_PASS=FW2YourSecretPassword
# Device: ...
```
Note: The script currently expects these exact variable names. If you add more firewalls to the devices list in the script, ensure you add the corresponding USER and PASS keys to this file.
* **Update the Device Inventory:**
Add your username and managment ip adress into the Device Inventory part of the script
``` python
devices = [
    {
        "hostname": "FW1",
        "host": "1.1.1.1",
        "username": os.getenv("FW1_USER"),
        "password": os.getenv("FW1_PASS")
    },
    {
        "hostname": "FW2",
        "host": "2.2.2.2",
        "username": os.getenv("FW2_USER"),
        "password": os.getenv("FW2_PASS")
    }
]
``` 

* **Run:**
``` python
python BACKUP_PANOS.py
```
## Option 2: PowerShell (Windows Native)

The PowerShell version is perfect for Windows admins who want a script that handles its own module installation and uses Windows-integrated encryption.

### Features
* **Auto-Provisioning:** Automatically installs the `Posh-SSH` module and required `NuGet` providers if missing.
* **Encrypted Passwords:** Uses Windows Data Protection API (DPAPI) so passwords aren't stored in plain text.
* **Clean Output:** Automatically strips CLI artifacts like [edit], --More--, and command echos to provide a clean set format config file.
* **Automated Workflow:** Sets the CLI pager off and output format to set before fetching the configuration.

### Setup & Usage
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

## Common Troubleshooting
* **Ping Check:** Ensure you can ping the firewalls. If the script fails to connect, check the Management Permitted IP list on the Palo Alto device.
* **Module Issues:** If the script hangs on "Checking prerequisites," ensure you have internet access for the initial download of the Posh-SSH module.
* **New Machine:** If you move this script to a different computer, the Pass strings will become invalid. You will need to repeat Step 1 on the new machine.

