import os
from netmiko import ConnectHandler
from datetime import datetime
from dotenv import load_dotenv

# 0. Load the secrets from the .env file
load_dotenv()

# 1. Configuration & Inventory
BACKUP_DIR = r"C:\Kenneth\BACKUP Config"
DATE_STR = datetime.now().strftime("%Y%m%d")

if not os.path.exists(BACKUP_DIR):
    os.makedirs(BACKUP_DIR)

# Device Inventory
devices = [
    {
        "hostname": "FW1",
        "host": "192.168.143.99",
        "username": os.getenv("FW1_USER"),
        "password": os.getenv("FW1_PASS")
    },
    {
        "hostname": "FW2",
        "host": "192.168.143.54",
        "username": os.getenv("FW2_USER"),
        "password": os.getenv("FW2_PASS")
    }
]

# 2. Main Execution Loop
for device in devices:
    # Basic check to ensure we actually got a password
    if not device['password']:
        print(f"SKIPPING {device['hostname']}: No password found in environment!")
        continue
    print(f"\n--- Connecting to {device['hostname']} ({device['host']}) ---")
    
    connection_params = {
        'device_type': 'paloalto_panos',
        'host': device['host'],
        'username': device['username'],
        'password': device['password'],
    }

    try:
        # Establish Connection
        with ConnectHandler(**connection_params) as net_connect:
            print("Setting CLI format and entering config mode...")
            
            # Netmiko handles paging (set cli pager off) automatically!
            # We match your PS logic by setting format to 'set'
            net_connect.send_command('set cli config-output-format set')
            
            # Use Netmiko's built-in config mode method
            net_connect.config_mode()
            
            print("Fetching configuration...")
            # Netmiko waits for the prompt automatically
            config_data = net_connect.send_command('show')
            
            # 3. Clean the Output (Same logic as your PS 'CleanedLines')
            # Removes lines that are just the 'show' command, prompts, or empty
            lines = config_data.splitlines()
            cleaned_lines = [
                line for line in lines 
                if line.strip() and 
                not line.strip().startswith('show') and 
                '[edit]' not in line and
                not line.strip().endswith('#')
            ]
            
            final_output = "\n".join(cleaned_lines)
            
            # Save to file
            file_path = os.path.join(BACKUP_DIR, f"{device['hostname']}-{DATE_STR}.txt")
            with open(file_path, "w", encoding='utf-8') as log_file:
                log_file.write(final_output)
                
            print(f"SUCCESS: Saved to {file_path}")

    except Exception as e:
        print(f"FAILED: {e}")

print("\nAll tasks completed.")
