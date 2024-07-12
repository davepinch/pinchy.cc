
#
# Make sure the powershell-yaml module is installed.
#
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {

    Write-Host `
        "This script requires the powershell-yaml module." `
        -ForegroundColor White `
        -BackgroundColor Red

    "You can install the module with the following command:"
    "Install-Module -Name powershell-yaml"
    "For more info, see https://github.com/cloudbase/powershell-yaml"

    # Note: this PowerShell script does not automatically execute
    # the installation command as it requires user interaction and
    # you may prefer different options than the default.
    exit
}

#
# Get all .md files in all subdirectories
#
$rootPath = $PSScriptRoot
$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -Recurse

foreach ($mdFile in $mdFiles) {

    $mdFile.Name

    #
    # Check for a common error of a directory with a .md extension
    #
    if ($mdFile.Attributes -band [System.IO.FileAttributes]::Directory) {
        Write-Warning "Directory with .md extension: $($mdFile.FullName)"
        continue
    }

    #
    # Skip files called README.md
    #
    if ($mdFile.Name -eq "README.md") {
        continue
    }

    #
    # Get the contents of the file as a string array
    #
    $content = Get-Content -Path $mdFile.FullName

    #
    # Ensure the first line is ---
    #
    if ($content[0] -ne "---") {
        Write-Warning "First line must be ---: $($mdFile.FullName)"
        continue
    }   
}