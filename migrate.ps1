
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
