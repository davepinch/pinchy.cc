
#
# Track whether any warnings or issues found.
#
$foundProblems = $false;

#
# Make sure the powershell-yaml module is installed.
#
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {

    Write-Host `
        "This script requires the powershell-yaml module." `
        -ForegroundColor White `
        -BackgroundColor Red

    "You can install the module with the following command:"
    "Install-Module -Name powershell-yaml -Scope CurrentUser"
    "For more info, see https://github.com/cloudbase/powershell-yaml"

    # Note: this PowerShell script does not automatically execute
    # the installation command as it requires user interaction and
    # you may prefer different options than specified.
    #
    # When installing for the first time, you may get an error message
    # that the NuGet provider is required to continue. If so, you can
    # install immediately, or exit and install it separately. You
    # may also get a warning that the repository is untrusted. As
    # long as the repository is PSGallery, you can trust it.
    $foundProblems = $true
    exit
}

#
# Get all .md files in all subdirectories
#
$rootPath = $PSScriptRoot
$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -Recurse

foreach ($mdFile in $mdFiles) {

    #
    # Check for a common error of a directory with a .md extension
    #
    if ($mdFile.Attributes -band [System.IO.FileAttributes]::Directory) {
        $foundProblems = $true
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
    # Make sure the first line is the start of YAML front matter (---)
    #
    if ($content[0] -ne "---") {
        $foundProblems = $true
        Write-Warning "No YAML front matter in: $($mdFile.FullName)"
        continue
    }

    # 
    # Get the array index of the second "---" in the array
    # 
    $endOfYaml = -1
    for ($i = 1; $i -lt $content.Length; $i++) {
        if ($content[$i] -eq "---") {
            $endOfYaml = $i
            break
        }
    }

    if ($endOfYaml -eq -1) {
        $foundProblems = $true
        Write-Warning "No end of YAML front matter: $($mdFile.FullName)"
        continue
    }

    #
    # Make sure the first property is the title
    #
    if ($content[1] -notmatch "^title: ") {
        $foundProblems = $true
        Write-Warning "Title must be first in YAML front matter: $($mdFile.FullName)"
        continue
    }
    
    #
    # Parse the YAML front matter
    #
    try {
        $yaml = $content[1..($endOfYaml - 1)] | ConvertFrom-Yaml
    }
    catch {
        $foundProblems = $true
        Write-Warning "Error parsing YAML front matter: $($mdFile.FullName)"
        continue
    }

    #
    # url must start and end with a forward slash
    #
    if ($null -ne $yaml.url) {
        if ($yaml.url -notmatch "^/.*?/$") {
            $foundProblems = $true
            Write-Warning "url property must start and end with a forward slash: $($mdFile.FullName)"
        }
    }

    #
    # website required if the type is website
    #
    if ($yaml.type -eq "website") {
        if ($null -eq $yaml.website) {
            $foundProblems = $true
            Write-Warning "Website property is required for type website: $($mdFile.FullName)"
        }
    }
}

#
# Summarize the results
#
if ($foundProblems) {
    Write-Host "Problems found." `
         -ForegroundColor White `
         -BackgroundColor Red
    Write-Host "In VSCode, ctrl+click the file path to open."
}
else {
    Write-Host "No problems found." `
        -ForegroundColor White `
        -BackgroundColor Green
    Write-Host "Testing can only prove the presence of bugs, not their absence."
    Write-Host "  - Edsger W. Dijkstra"
}