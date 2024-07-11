
# Get all .md files in all subdirectories
$rootPath = $PSScriptRoot
$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -Recurse

foreach ($mdFile in $mdFiles) {

    #
    # A directory with a .md extension is not a markdown
    # file and is most likely an error. Skip it.
    #
    if ($mdFile.Attributes -band [System.IO.FileAttributes]::Directory) {
        Write-Warning "Directory with .md extension: $($mdFile.FullName)"
        continue
    }

}