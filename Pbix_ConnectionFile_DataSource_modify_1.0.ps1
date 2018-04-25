$PSScriptRoot = Get-Location

$PSScriptRoot
$Source = "$PSScriptRoot\Sales Trend-Brand Summary_2.71GB.pbix"
$Dest = "$PSScriptRoot\Sales Trend-Brand Summary_2.71GB.zip"
$UnzipDest = "$PSScriptRoot\Sales Trend-Brand Summary_2.71GB"
$UnzipDest

Rename-Item $Source $Dest

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip $Dest $UnzipDest


$Source_File = "asazure://northeurope.asazure.windows.net/bataspdnepetradevquery"
$Target_IP = "asazure://northeurope.asazure.windows.net/bataspdnepetradevquery-replaced"
$PSScriptRoot = Get-Location
(Get-Content "$PSScriptRoot\Sales Trend-Brand Summary_2.71GB\connections" | out-string).Replace($Source_File,$Target_IP) | Set-Content "$PSScriptRoot\Sales Trend-Brand Summary_2.71GB\connections"
Remove-Item $Dest

Add-Type -AssemblyName "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory($UnzipDest, $Dest)

Rename-Item $Dest $Source
Remove-Item $UnzipDest -recurse -Force


