# PowerStore PRTG Alert Monitor
<img width="1107" alt="image" src="https://github.com/user-attachments/assets/110a7a3d-23a7-4e7a-82f8-33436992bf90">


## Description
This PowerShell script monitors Dell PowerStore storage systems for unacknowledged alerts and integrates with PRTG Network Monitor. It retrieves alert data from the PowerStore REST API and formats it for PRTG, providing immediate notification when unacknowledged alerts are present in the system.

## Features
- Monitors all unacknowledged alerts in the PowerStore system
- Reports the following information:
  - Count of unacknowledged alerts
  - Detailed descriptions of each alert
  - Severity level of each alert
- Automatically triggers error state (red) when any unacknowledged alerts are present
- Outputs results in PRTG-compatible JSON format
- Handles SSL certificate errors for environments with self-signed certificates
- Provides detailed error messages for troubleshooting

## Prerequisites
- PowerShell 5.1 or later
- PRTG Network Monitor
- Access to PowerStore REST API (IP address/hostname, username, and password)
- TLS 1.2 support

## Installation
1. Clone this repository or download the `PowerStore-Alert-PRTG-Sensor.ps1` file
2. Place the script in your PRTG Custom Sensors directory, typically:
   `C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXE`

## Usage
In PRTG, create a new sensor using the "EXE/Script Advanced" sensor type. Add PowerStore account to the Windows Credentials section for the device in PRTG. Use the following parameters:

- **Sensor Name:** PowerStore Alert Monitor
- **Parent Device:** Your PowerStore device in PRTG
- **Inherit Access Rights:** Yes
- **Scanning Interval:** 5 minutes (or as needed)
- **EXE/Script:** PowerStore-Alert-PRTG-Sensor.ps1
- **Parameters:** -PowerStoreIP %host -Username %windowsuser -Password %windowspassword

Replace `%host`, `%windowsuser`, and `%windowspassword` with the appropriate placeholders if not using Windows Credentials in PRTG.

## Sensor Behavior
The sensor will:
- Show GREEN status when there are no unacknowledged alerts
- Show RED status when any unacknowledged alerts are present
- Display the number of unacknowledged alerts
- List all unacknowledged alerts with their severity levels and descriptions in the sensor message

## Error Handling
The script handles several error conditions:
- API connection failures
- Authentication errors
- SSL/TLS issues
- Invalid responses

All errors are properly formatted for PRTG and will trigger an error state with appropriate messages.

## Troubleshooting
- Ensure that the PowerStore REST API is accessible from the PRTG probe server
- Verify that the provided credentials have sufficient permissions to access the PowerStore API
- Check PRTG logs for any execution errors
- Verify TLS 1.2 is enabled on the PRTG probe server

Common issues:
1. SSL Certificate Errors: The script includes SSL certificate handling for self-signed certificates
2. Authentication Failures: Verify credentials and permissions
3. Network Connectivity: Ensure probe server can reach PowerStore management IP

## License
Distributed under the MIT License. See `LICENSE` file for more information.

## Contact
Richard Travellin - richard.travellin@computacenter.com

Project Link: https://github.com/CC-Digital-Innovation/PowerStore-PRTG-Alert-Monitor

## Acknowledgements
- [Dell PowerStore](https://www.dell.com/en-us/dt/storage/powerstore-storage-appliance.htm)
- [PRTG Network Monitor](https://www.paessler.com/prtg)

## Version History
- 1.0: Initial release
  - Basic alert monitoring functionality
- 1.1: Updated error handling
  - Improved error state triggering
  - Enhanced alert message formatting
