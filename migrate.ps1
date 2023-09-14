
#
# Script to migrate from Jekyll to Hugo
#
# - Stop the Hugo server before running this script.
# - Run this script from the root of the project.
#

#
# .gitignore (overwrite)
#
Set-Content -Path ".gitignore" -Value ".hugo_build.lock"

#
# _sass/ (move to assets/sass)
#
if (Test-Path -Path "_sass") {
  if (!(Test-Path -Path "assets\sass")) {
    Move-Item -Path "_sass" -Destination "assets\sass"
  }
}

#
# _site/ (delete)
#
If (Test-Path -Path "_site") {
  Remove-Item -Path "_site" -Recurse -Force
}

#
# assets/css/style.scss (delete)
#
If (Test-Path -Path "assets\css\styles.scss") {
  Remove-Item -Path "assets\css\styles.scss"
}

#
# assets/css/ (delete if empty)
#
if (Test-Path -Path "assets\css") {
  if (!(Get-ChildItem -Path "assets\css")) {
    Remove-Item -Path "assets\css"
  }
}


#
# collections/ (rename to content)
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
# content/404.md (import)
#
if (Test-Path -Path "_pages\404.md") {
  Move-Item -Path "_pages\404.md" -Destination "content\404.md"
}

#
# _pages/ (delete)
#
if (Test-Path -Path "_pages") {
  if (!(Get-ChildItem -Path "_pages")) {
    Remove-Item -Path "_pages"
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
Set-Content -Path "layouts\_default\baseof.html" -Value @'
<!doctype html>
<html lang="en">
<head>
 <meta charset="utf-8">
 <meta name="viewport" content="width=device-width, initial-scale=1">
 <title>{{ .Page.Title }}</title>
 {{ $style := resources.Get "sass/cc.scss" | resources.ToCSS | resources.Minify }}
 <link rel="stylesheet" href="{{ $style.Permalink }}"> 
</head>
<body>
 {{ block "main" . }}
 {{ end }}
</body>
</html>
'@

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