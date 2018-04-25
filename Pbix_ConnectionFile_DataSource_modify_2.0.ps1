 Param(
                [Parameter(Mandatory=$True,Position=1)]
                
                [string]$inputdir,
                [Parameter(Mandatory=$True)]
                [string]$Update_url
                #[switch]$force = $false
                )


# section of code to change the file name to .zip

$proj_files = Get-ChildItem $inputdir | Where-Object {$_.Extension -eq ".pbix"}

ForEach ($file in $proj_files) {
#$file.Name
$filenew = $file.Name + ".zip"

$ExtractFol_1=$filenew.Substring(0,$filenew.Length-9)
#$ExtractFol_1

$b=New-Item $inputdir\$ExtractFol_1 -ItemType Directory
# directory to unzip the folder is done


Move-Item  $inputdir\$file $inputdir\$filenew
#renaming to .zip is complete till here

$zippedfile="$inputdir\$filenew"

#function to unzip to a folder.

function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

$unzippedfolpath="$inputdir\$ExtractFol_1"


unzip $zippedfile $inputdir\$ExtractFol_1

# folder path to be zipped now


$proj = Get-ChildItem $inputdir | Where-Object {$_.Extension -eq ".zip"}

foreach ($proj1 in $proj) {

$ziprmv="$inputdir\$proj1"

Remove-Item $ziprmv

}


$initial_content = "asazure://northeurope.asazure.windows.net/bataspdnepetradevquery"
#$updated_content = "asazure://northeurope.asazure.windows.net/bataspdnepetradevquery-replaced"

$PSScriptRoot = (Get-Content "$unzippedfolpath\connections" | out-string).Replace($initial_content,$Update_url) | Set-Content "$unzippedfolpath\connections"

# folder path to be zipped now   $inputdir\$ExtractFol_1

#$unzippedfolpath

$zf="$unzippedfolpath.zip"

#foreach ($r in $inputdir) {
#If(Test-path $zf) {Remove-item $zf}
#Add-Type -assembly "system.io.compression.filesystem" 
#[io.compression.zipfile]::CreateFromDirectory($unzippedfolpath, $zf)

#}

}

$Folders = get-childitem -dir $inputdir

foreach ($Folder in $Folders) {

$FolderPath = $Folder.FullName

$FolderName = $Folder.BaseName

#if (!(Test-Path $FolderPath -include "$Folder.zip")) {


Add-Type -assembly "system.io.compression.filesystem" 


[io.compression.zipfile]::CreateFromDirectory("$FolderPath", "$FolderPath\..\$FolderName.zip")

#}
Remove-Item $FolderPath -Force -Recurse

}
$fzifile=Get-ChildItem $inputdir

foreach($fzifile1 in $fzifile) {

$finalfile = $fzifile1.BaseName + ".pbix"
$Finalzip="$inputdir\$fzifile1"
$Finalpbix="$inputdir\$finalfile"
Rename-Item $Finalzip $Finalpbix


} 












