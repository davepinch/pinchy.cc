(Get-ChildItem -Path "collections\_reality-checks" -Filter "*.md" -Recurse) | ForEach-Object {
  
    $file = $_
    $name = $file.BaseName
  
    # Create a folder with the same name as the .md file (minus extension)
    $oldDir = $file.DirectoryName
    $newDir = Join-Path -Path $oldDir -ChildPath $name
    New-Item -Path $newDir -ItemType Directory
  
    # Move the .md file into the new directory
    Move-Item -Path $file.FullName -Destination $newDir
}
