
#
# Script to migrate from Jekyll to Hugo
#
# - Stop the Hugo server before running this script.
# - Run this script from the root of the project.
#

#
# .gitignore (overwrite)
#
Set-Content -Path ".gitignore" -Value @"
.hugo_build.lock
/resources/
"@

#
# _config.yml (delete)
#
If (Test-Path -Path "_config.yml") {
  Remove-Item -Path "_config.yml"
}

#
# _layouts/root.html (delete)
#
If (Test-Path -Path "_layouts/root.html") {
  Remove-Item -Path "_layouts/root.html"
}


#
# _sass/ (move to assets/sass)
#
if (Test-Path -Path "_sass") {
  if (Test-Path -Path "assets\sass") {
    if (!(Get-ChildItem -Path "assets\sass")) {
      Remove-Item -Path "assets\sass"
    }
  }
  Move-Item -Path "_sass" -Destination "assets\sass"
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
# _pages/404.md (delete)
#
if (Test-Path -Path "_pages\404.md") {
  Remove-Item -Path "_pages\404.md"
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
[permalinks]
  about = '/:filename/'
"@

#
# layouts/ (create)
#
If (!(Test-Path -Path "layouts")) {
  New-Item -Path "layouts" -ItemType Directory
}

#
# layouts/_default/ (create)
#
If (!(Test-Path -Path "layouts\_default")) {
  New-Item -Path "layouts\_default" -ItemType Directory
}

#
# layouts/_default/baseof.html (create)
#
Set-Content -Path "layouts\_default\baseof.html" -Value @'
<!DOCTYPE html>
<html lang="en">
<head>
 <meta charset="utf-8">
 <meta name="viewport" content="width=device-width, initial-scale=1">
 <title>{{ .Page.Title }}</title>
 {{ $style := resources.Get "sass/cc.scss" | resources.ToCSS | resources.Minify }}
 <link rel="stylesheet" href="{{ $style.Permalink }}">
 <link rel="shortcut icon" type="image/x-icon" href="/favicon/favicon.ico"/>
</head>
<body>
 {{ block "main" . }}
 {{ end }}
 {{ partial "footer.html" . }}
</body>
</html>
'@

#
# layouts/_default/list.html (create)
#
Set-Content -Path "layouts\_default\list.html" -Value @"
{{ define "main" }}
{{ .Content }}
{{ end }}
"@

#
# layouts/_default/masthead.html (create)
#
Set-Content -Path "layouts\_default\masthead.html" -Value @"
<header class="cc-masthead cc-{{ .Type }}-masthead">
  <h1 class="cc-title">{{ .Params.title }}</h1>
</header>
"@

#
# layouts/_default/single.html (create)
#
Set-Content -Path "layouts\_default\single.html" -Value @"
{{ define "main" }}
{{ .Render "masthead" }}
{{ .Content }}
{{ end }}
"@

#
# layouts/404.html (create)
#
Set-Content -Path "layouts\404.html" -Value @"
{{ define "main" }}
<p>Sorry, but this page hasn't been constructed yet.</p>
<a href='{{ "" | relURL }}'>Go Home</a>
{{ end }}
"@

#
# layouts/partials/ (create)
#
If (!(Test-Path -Path "layouts\partials")) {
  New-Item -Path "layouts\partials" -ItemType Directory
}

#
# layouts/partials/footer.html (create)
#
Set-Content -Path "layouts\partials\footer.html" -Value @"
<hr />
<footer class="cc-footer">
  <menu>
    <li>
      <a href="/index.html">home</a>
    </li>
    <li>
      <a href="/about-me/">about</a>
    </li>
    <li>
      <a href="/privacy-policy/">privacy</a>
    </li>
  </menu>
</footer>
"@

#
# static/ (recreate)
#
If (Test-Path -Path "static") {
  Remove-Item -Path "static" -Recurse -Force
}
New-Item -Path "static" -ItemType Directory

#
# static/favicon/ (move from assets)
#
Move-Item -Path "assets\favicon" -Destination "static\favicon"

#
# static/favicon.ico (copy for root of website)
#
Move-Item -Path "favicon.ico" -Destination "static\favicon.ico"