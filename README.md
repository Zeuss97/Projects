# Projects
# Snipe-IT PowerShell Asset Updater

This project is a PowerShell script to collect hardware information from a Windows computer and automatically synchronize it with the Snipe-IT inventory system using its REST API.

## Features

- Collects:
- Computer name
- Serial number
- Model and manufacturer
- Operating system
- Processor (CPU)
- RAM
- Primary disk
- MAC address
- All IPv4 IP addresses
- Searches for the asset by serial number in Snipe-IT and:
- If it exists: updates the asset data (without changing the serial number)
- If it doesn't exist: creates a new asset
- Records all relevant information in the asset's notes field.
- Handles errors and displays detailed API responses.

## Requirements

- Windows 10/11 or Server with PowerShell 5.x or higher
- Network access to the Snipe-IT server and a valid **API Token**
- Permissions to run PowerShell scripts

## Installation

1. **Download the script**
Download the `snipe-it script.ps1` file from this repository.

2. **Edit the script:**
Open `snipe-it script.ps1` in your favorite editor and replace the line:
```powershell
$ApiToken = "<YOUR_TOKEN_HERE>"
```
with your actual Snipe-IT API Token.

3. **(Optional) Adjust the IDs:**
If desired, adjust the `model_id` and `status_id` values ​​to match your Snipe-IT installation.

## Usage

1. **Run PowerShell as administrator**
2. Navigate to the folder where you saved `snipe-it script.ps1`
3. Run:
```powershell
.\ssnipe-it script.ps1
```
4. Follow the on-screen instructions.

## Technical Notes

- The script first searches for the asset by its serial number; if found, it updates only the configured fields (never the serial number); if not, it creates it.
- All IPv4 addresses assigned to the device are added to the `notes` field, along with the rest of the hardware information.
- The script handles IP collection automatically for PowerShell 5.x and 7+.
- The `notes` field can be customized to add/remove information according to your needs.

## License

MIT

## Credits

Developed by Zeuss97 with help from GitHub Copilot.
