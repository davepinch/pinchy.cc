
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
# content (renamed from collections)
#
if (Test-Path -Path "collections") {
  if (!(Test-Path -Path "content")) {
    Rename-Item -Path "collections" -NewName "content"
  }
}

#
# content/_* (remove prefix)
#
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
# content/_index.md (create)
#
Set-Content -Path "content/_index.md" -Value @"
---
title: "pinchy.cc"
---
hello world
"@

#
# layout/ (create)
#
If (!(Test-Path -Path "layouts")) {
  New-Item -Path "layouts" -ItemType Directory
}

#
# layout/_default/ (create)
#
If (!(Test-Path -Path "layouts\_default")) {
  New-Item -Path "layouts\_default" -ItemType Directory
}


#
# layout/_default/baseof.html (create)
#
Set-Content -Path "layouts\_default\baseof.html" -Value @"
<!doctype html>
<html>
<head>
 <meta charset="utf-8">
 <title>{{ .Page.Title }}</title>
</head>
<body>
 {{ block "main" . }}
 {{ end }}
</body>
</html>
"@

#
# layout/_default/list.html (create)
#
Set-Content -Path "layouts\_default\list.html" -Value @"
{{ define "main" }}
{{ .Content }}
{{ end }}
"@

#
# layout/_default/single.html (create)
#
Set-Content -Path "layouts\_default\single.html" -Value @"
{{ define "main" }}
{{ .Content }}
{{ end }}
"@

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
