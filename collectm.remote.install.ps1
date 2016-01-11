[CmdletBinding()]
Param(

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$collectMRepo="https://github.com/perfwatcher/collectm/releases/",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$collectMScriptRepo="https://github.com/mistio/deploy_collectm",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$scriptGitBranch="master",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
	[string]$version="latest",

    [Parameter(Mandatory=$false)]
    [switch]$SetupConfigFile=$false,

    [Parameter(Mandatory=$false)]
	[string]$setupArgs

)

function downloadFile($url, $filePath) {
    "Downloading $url"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    ## 15 second timeout ##
    $request.set_Timeout(15000)
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $filePath, Create
    $buffer = New-Object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    $iterations = 0
    $startLeft = [Console]::CursorLeft
    $startTop = [Console]::CursorTop
    while ($count -gt 0) {
        [Console]::SetCursorPosition($startLeft, $startTop)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
        $iterations += 1
        if (($iterations % 130 -eq 0) -or ([System.Math]::Floor($downloadedBytes/1024) -eq $totalLength)) {
            [System.Console]::Write("Downloaded {0}K of {1}K`n", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        }
    }
    Write-Host "Finished Download"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

if ($SetupConfigFile -eq $true -and !$setupArgs) {
    Write-Host "You want the config file to be updated but you didn't give any arguments for the collectm.config script!"
    Exit
 }


if ($version -ne "latest") {
tag/v
    $collectmDownloadUrl = "https://github.com/perfwatcher/collectm/releases/tag/v" + $version
} else {
    $collectmDownloadUrl = "https://github.com/perfwatcher/collectm/releases/latest"
}

$collectmDeployScriptUrl = $collectMScriptRepo + "/blob/" + $scriptGitBranch + "/collectm.deploy.ps1?raw=true"

$collectmConfigScriptUrl = $collectMScriptRepo + "/blob/" + $scriptGitBranch + "/collectm.config.ps1?raw=true"

$collectmDownloadScriptUrl = $collectMScriptRepo + "/blob/" + $scriptGitBranch + "/collectm.download.ps1?raw=true"

$installerPath = "collectm.installer.exe"

Write-Host "Fetching download script in url: ""$collectmDownloadScriptUrl"""

downloadFile -url "$collectmDownloadScriptUrl" -filePath ".\collectm.download.ps1"

Write-Host "Downloading CollectM installer: .\collectm.download.ps1 -url ""$collectmDownloadUrl"" -filePath ""$installerPath"""

Invoke-Expression ".\collectm.download.ps1 -url $collectmDownloadUrl -filePath $installerPath"

Write-Host "Downloading CollectM deploy script: .\collectm.download.ps1 -url ""$collectmDeployScriptUrl"" -filePath 'collectm.deploy.ps1'"

Invoke-Expression ".\collectm.download.ps1 -url ""$collectmDeployScriptUrl"" -filePath 'collectm.deploy.ps1'"

Write-Host "Downloading Collectm config script: .\collectm.download.ps1 -url ""$collectmConfigScriptUrl"" -filePath 'collectm.config.ps1'"

Invoke-Expression ".\collectm.download.ps1 -url ""$collectmConfigScriptUrl"" -filePath 'collectm.config.ps1'"

if ($SetupConfigFile -eq $true) {
    $temp = ".\collectm.deploy.ps1 -installerPath ""$installerPath"" -SetupConfigFile -configArgs '" + $setupArgs + "'"
    Write-Host "Running: $temp"
    Invoke-Expression "$temp"
} else {
    Write-Host "Running: .\collectm.deploy.ps1 -installerPath ""$installerPath"""
    Invoke-Expression ".\collectm.deploy.ps1 -installerPath ""$installerPath"""
}