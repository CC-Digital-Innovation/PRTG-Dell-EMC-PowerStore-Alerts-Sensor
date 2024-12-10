{\rtf1\ansi\ansicpg1252\cocoartf2820
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 <#\
.SYNOPSIS\
Monitors unacknowledged alerts for Dell PowerStore systems and outputs the results to PRTG.\
\
.DESCRIPTION\
This script retrieves active alerts from the PowerStore REST API. It filters for unacknowledged alerts and outputs PRTG sensor results with information on the number of unacknowledged alerts and their detailed descriptions. The script triggers an error state when any unacknowledged alerts are present to ensure immediate attention from monitoring teams.\
\
.PARAMETER PowerStoreIP\
The IP address or hostname of the PowerStore management system.\
\
.PARAMETER Username\
The username for accessing the PowerStore REST API.\
\
.PARAMETER Password\
The password for accessing the PowerStore REST API.\
\
.INPUTS\
None.\
\
.OUTPUTS\
Outputs PRTG sensor results with information on unacknowledged alerts for the specified PowerStore system. Includes:\
- Count of unacknowledged alerts\
- Severity level and description for each unacknowledged alert\
- Error state when unacknowledged alerts are present\
\
.NOTES\
Author: Richard Travellin\
Date: 12/09/2024\
Version: 1.1\
Rest API Version: PowerStore REST API v3\
Dependencies: PowerShell 5.1 or higher, TLS 1.2 support\
\
.EXAMPLE\
./PowerStore-Alert-PRTG-Sensor.ps1 -PowerStoreIP "10.10.10.15 -Username "admin" -Password "password"\
This example runs the script to check for unacknowledged alerts on the PowerStore system at the specified IP address using the provided credentials.\
#>\
# PowerStore Alert PRTG Sensor Script\
\
param (\
    [Parameter(Mandatory=$true)]\
    [string]$PowerStoreIP,\
    \
    [Parameter(Mandatory=$true)]\
    [string]$Username,\
    \
    [Parameter(Mandatory=$true)]\
    [string]$Password\
)\
\
# Disable SSL verification\
add-type @"\
    using System.Net;\
    using System.Security.Cryptography.X509Certificates;\
    public class TrustAllCertsPolicy : ICertificatePolicy \{\
        public bool CheckValidationResult(\
            ServicePoint srvPoint, X509Certificate certificate,\
            WebRequest request, int certificateProblem) \{\
            return true;\
        \}\
    \}\
"@\
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy\
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12\
\
# Create credentials and convert to Base64\
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("\{0\}:\{1\}" -f $Username,$Password)))\
\
# Set up headers\
$headers = @\{\
    Authorization = "Basic $base64AuthInfo"\
    Accept = "application/json"\
\}\
\
try \{\
    # Make REST API call\
    $uri = "https://$PowerStoreIP/api/rest/alert?select=*"\
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get\
\
    # Filter for unacknowledged alerts\
    $unackAlerts = $response | Where-Object \{ $_.is_acknowledged -eq $false \}\
    $alertCount = $unackAlerts.Count\
\
    # Build message with descriptions\
    $message = ""\
    if ($alertCount -gt 0) \{\
        $message = "ERROR: Found $alertCount unacknowledged alert(s):`n"\
        foreach ($alert in $unackAlerts) \{\
            $severity = $alert.severity_l10n\
            $message += "[$severity] $($alert.description_l10n)`n"\
        \}\
    \} else \{\
        $message = "OK: No unacknowledged alerts"\
    \}\
\
    # Format output for PRTG\
    $output = @\{\
        prtg = @\{\
            result = @(\
                @\{\
                    channel = "Unacknowledged Alerts"\
                    value = $alertCount\
                    unit = "Count"\
                \}\
            )\
            text = $message\
            error = if ($alertCount -gt 0) \{ 1 \} else \{ 0 \}\
        \}\
    \}\
\
    # Output JSON\
    $output | ConvertTo-Json -Depth 5\
    \
    # Exit with error if there are unacknowledged alerts\
    if ($alertCount -gt 0) \{\
        exit 2  # Error state in PRTG\
    \} else \{\
        exit 0  # OK state in PRTG\
    \}\
\}\
catch \{\
    # Error output for PRTG\
    @\{\
        prtg = @\{\
            error = 1\
            text = "Error accessing PowerStore API: $($_.Exception.Message)"\
        \}\
    \} | ConvertTo-Json\
    exit 2\
\}}