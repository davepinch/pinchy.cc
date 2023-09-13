
#
# Script to migrate from Jekyll to Hugo
#

#
# .gitignore (overwrite)
#
Set-Content -Path ".gitignore" -Value ".hugo_build.lock"

#
# _site (delete)
#
If (Test-Path -Path "_site") {
  Remove-Item -Path "_site" -Recurse -Force
}

#
# collections (rename)
#
if (Test-Path -Path "collections") {
  if (!(Test-Path -Path "content")) {
    Rename-Item -Path "collections" -NewName "content"
  }
}

# In the content directory, rename each subdirectory that has an
# understore prefix to remove the underscore
Get-ChildItem -Path "content" -Directory | ForEach-Object {
  $dir = $_
  if ($dir.Name.StartsWith("_")) {
    $newName = $dir.Name.Substring(1)
    Rename-Item -Path $dir.FullName -NewName $newName
  }
}


#
# Gemfile (delete)
# 
If (Test-Path -Path "Gemfile") {
  Remove-Item -Path "Gemfile"
}

#
# Gemfile.lock (delete)
#
If (Test-Path -Path "Gemfile.lock") {
  Remove-Item -Path "Gemfile.lock"
}

#
# go.mod (create)
#
Set-Content -Path "go.mod" -Value @"
module github.com/davepinch/pinchy.cc
go 1.21
"@

#
# hugo.toml (create)
#
Set-Content -Path "hugo.toml" -Value @"
baseURL = 'https://pinchy.cc/'
defaultContentLanguage = 'en'
"@
