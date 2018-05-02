# This sample script calls the Power BI API to programmatically duplicate the workspace and all
# its dashboards, reports and datasets.

# For more information, see the accompanying blog post:
# https://powerbi.microsoft.com/en-us/blog/duplicate-workspaces-using-the-power-bi-rest-apis-a-step-by-step-tutorial/

# Instructions:
# 1. Install PowerShell (https://msdn.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell) 
#    and the Azure PowerShell cmdlets (Install-Module AzureRM)
# 2. Run PowerShell as an administrator
# 3. Follow the instructions below to fill in the client ID
# 4. Change PowerShell directory to where this script is saved
# 5. > ./copyworkspace.ps1

# Parameters - fill these in before running the script!
# ======================================================

# AAD Client ID
# To get this, go to the following page and follow the steps to provision an app
# https://dev.powerbi.com/apps
# To get the sample to work, ensure that you have the following fields:
# App Type: Native app
# Redirect URL: urn:ietf:wg:oauth:2.0:oob
#  Level of access: check all boxes

$clientId = " FILL ME IN " 

# End Parameters =======================================

# TODO: move helper functions into a separate file
# Calls the Active Directory Authentication Library (ADAL) to authenticate against AAD
function GetAuthToken
{
    $adal = "${env:ProgramFiles}\WindowsPowerShell\Modules\AzureRM.profile\4.6.0\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    
    $adalforms = "${env:ProgramFiles}\WindowsPowerShell\Modules\AzureRM.profile\4.6.0\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"

    $authority = "https://login.microsoftonline.com/common/oauth2/authorize";

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

    return $authResult
}


# PART 1: Authentication
# ==================================================================
$token = GetAuthToken

Add-Type -AssemblyName System.Net.Http
$temp_path_root = "$PSScriptRoot\pbi-copy-workspace-temp-storage"

# Building Rest API header with authorization token
$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

# Prompt for user input
# ==================================================================
# Get the list of groups that the user is a member of
$uri = "https://app.powerbi.com/"
$all_groups = (Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET).value
   
   
    $report_name = "Sales_Trend-Brand Summary_2.71GB"
                #Local pbix file path and name
                $temp_path_root="C:\pbixlocation"
    $temp_path = "$temp_path_root\$report_name.pbix"
    $target_group_path = "PSales_Trend-Brand Summary_2.71GB"
     
    try {
        "== Importing $report_name to target workspace"
        $uri = "https://api.powerbi.com/v1.0/$target_group_path/imports/?datasetDisplayName=$report_name.pbix&nameConflict=Abort"

        # Here we switch to HttpClient class to help POST the form data for importing PBIX
        $httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler
        $httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token.AccessToken);
        $packageFileStream = New-Object System.IO.FileStream @($temp_path, [System.IO.FileMode]::Open)
        
                    $contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
                    $contentDispositionHeaderValue.Name = "file0"
                    $contentDispositionHeaderValue.FileName = $file_name

        $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
        $streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
        
        $content = New-Object System.Net.Http.MultipartFormDataContent
        $content.Add($streamContent)

                    $response = $httpClient.PostAsync($Uri, $content).Result

                    if (!$response.IsSuccessStatusCode) {
                                    $responseBody = $response.Content.ReadAsStringAsync().Result
            "= This report cannot be imported to target workspace. Skipping..."
                                                $errorMessage = "Status code {0}. Reason {1}. Server reported the following message: {2}." -f $response.StatusCode, $response.ReasonPhrase, $responseBody
                                                throw [System.Net.Http.HttpRequestException] $errorMessage
                                } 
        
        # save the import IDs
        $import_job_id = (ConvertFrom-JSON($response.Content.ReadAsStringAsync().Result)).id

        # wait for import to complete
        $upload_in_progress = $true
        while($upload_in_progress) {
            $uri = "https://api.powerbi.com/v1.0/$target_group_path/imports/$import_job_id"
            $response = Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET
            
            if ($response.importState -eq "Succeeded") {
                "Publish succeeded!"
                # update the report and dataset mappings
                $report_id_mapping[$report_id] = $response.reports[0].id
                $dataset_id_mapping[$dataset_id] = $response.datasets[0].id
                break
            }

            if ($response.importState -ne "Publishing") {
                "Error: publishing failed, skipping this. More details: "
                $response
                break
            }
            
            Write-Host -NoNewLine "."
            Start-Sleep -s 5
        }
            
        
    } catch [Exception] {
        Write-Host $_.Exception
                    Write-Host "== Error: failed to import PBIX"
        Write-Host "= HTTP Status Code:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "= HTTP Status Description:" $_.Exception.Response.StatusDescription
        continue
    }

