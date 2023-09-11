
#
# Start of a script to migrate from Jekyll to Hugo
#

#
# Gemfile
# 
Remove-Item -Path "Gemfile"

#
# Gemfile.lock
#
Remove-Item -Path "Gemfile.lock"

#
# go.mod
#
Set-Content -Path "go.mod" -Value @"
module github.com/davepinch/pinchy.cc
go 1.21
"@

#
# hugo.toml
#
Set-Content -Path "hugo.toml" -Value @"
baseURL = 'https://pinchy.cc/'
defaultContentLanguage = 'en'
"@
