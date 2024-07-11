
# Get all .md files in all subdirectories
$rootPath = $PSScriptRoot
$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -Recurse

foreach ($mdFile in $mdFiles) {

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
    # Get the contents of the file as a single string with the -Raw parameter.
    # If -Raw is not used, Get-Content returns an array of strings.
    #
    $content = Get-Content -Path $mdFile.FullName -Raw

    #
    # Check if the first characters are ---
    #
    if ($content -notmatch '^---\r?\n') {
        Write-Warning "Invalid file format: $($mdFile.FullName)"
        continue
    }
    
}