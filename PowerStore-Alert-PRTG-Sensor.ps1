<#
.SYNOPSIS
Monitors unacknowledged alerts for Dell PowerStore systems and outputs the results to PRTG.

.DESCRIPTION
This script retrieves active alerts from the PowerStore REST API. It filters for unacknowledged alerts and outputs PRTG sensor results with information on the number of unacknowledged alerts and their detailed descriptions. The script triggers an error state when any unacknowledged alerts are present to ensure immediate attention from monitoring teams.

.PARAMETER PowerStoreIP
The IP address or hostname of the PowerStore management system.

.PARAMETER Username
The username for accessing the PowerStore REST API.

.PARAMETER Password
The password for accessing the PowerStore REST API.

.INPUTS
None.

.OUTPUTS
Outputs PRTG sensor results with information on unacknowledged alerts for the specified PowerStore system. Includes:
- Count of unacknowledged alerts
- Severity level and description for each unacknowledged alert
- Error state when unacknowledged alerts are present

.NOTES
Author: Richard Travellin
Date: 12/09/2024
Version: 1.1
Rest API Version: PowerStore REST API v3
Dependencies: PowerShell 5.1 or higher, TLS 1.2 support

.EXAMPLE
./PowerStore-Alert-PRTG-Sensor.ps1 -PowerStoreIP "10.10.100.4" -Username "admin" -Password "password"
This example runs the script to check for unacknowledged alerts on the PowerStore system at the specified IP address using the provided credentials.
#>
# PowerStore Alert PRTG Sensor Script

param (
    [Parameter(Mandatory=$true)]
    [string]$PowerStoreIP,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

# Disable SSL verification
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create credentials and convert to Base64
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))

# Set up headers
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    Accept = "application/json"
}

try {
    # Make REST API call
    $uri = "https://$PowerStoreIP/api/rest/alert?select=*"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

    # Filter for unacknowledged alerts and ensure we always have an array
    $unackAlerts = @($response | Where-Object { $_.is_acknowledged -eq $false })
    $alertCount = $unackAlerts.Count

    # Build message with descriptions
    $message = ""
    if ($alertCount -gt 0) {
        $message = "Found $alertCount unacknowledged alert(s):`n"
        foreach ($alert in $unackAlerts) {
            $severity = $alert.severity_l10n
            $message += "[$severity] $($alert.description_l10n)`n"
        }
    } else {
        $message = "No unacknowledged alerts"
    }

    # Format output for PRTG - with default error threshold
    $output = @{
        prtg = @{
            result = @(
                @{
                    channel = "Unacknowledged Alerts"
                    value = $alertCount
                    unit = "Count"
                    customunit = "Alerts"
                    showChart = 1
                    showTable = 1
                    limitmode = 1             # Enable limits
                    limitmaxerror = 0         # Error if value > 0
                    limitmaxerror_msg = "There are unacknowledged alerts that require attention"
                }
            )
            text = $message
        }
    }

    # Output JSON
    $output | ConvertTo-Json -Depth 5
    exit 0  # Always exit with OK state, let PRTG handle thresholds
}
catch {
    # Error output for PRTG - only used for actual script/connection errors
    @{
        prtg = @{
            error = 1
            text = "Error accessing PowerStore API: $($_.Exception.Message)"
        }
    } | ConvertTo-Json
    exit 2
}
