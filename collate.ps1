
#
# Track the number of warnings or issues found.
#
$foundProblems = 0

# ========================================================================
# Install powershell-yaml module
# ========================================================================

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
    $foundProblems++
    exit
}

# ========================================================================
# Load files
# ========================================================================

#
# Get all .md files in all subdirectories
#
$rootPath = $PSScriptRoot
$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -Recurse

#
# Define a case-sensitive hashtable of page titles for lookup and dupe checking.
#
#$titles = @{} # do not use - not case sensitive and dupes some emoji characters
$titles = [hashtable]::new()

#
# Define a hashtable to hold website type page titles
#
$websites = [hashtable]::new()

foreach ($mdFile in $mdFiles) {

    #
    # Get the relative path of the file for output
    #
    $mdPath = $mdFile.FullName -replace [regex]::Escape($rootPath + "\"), ''

    #
    # Check for a common error of a directory with a .md extension
    #
    if ($mdFile.Attributes -band [System.IO.FileAttributes]::Directory) {
        $foundProblems++
        Write-Warning "Directory has .md extension (probably a copy-paste error)"
        Write-Host $mdPath
        Write-Host
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
        $foundProblems++
        Write-Warning "First line must be --- to start YAML front matter"
        Write-Host $mdPath
        continue
    }

    # 
    # Get the array index of the second "---" in the lines of the file
    # 
    $endOfYaml = -1
    for ($i = 1; $i -lt $content.Length; $i++) {
        if ($content[$i] -eq "---") {
            $endOfYaml = $i
            break
        }
    }

    if ($endOfYaml -eq -1) {
        $foundProblems++
        Write-Warning "No end of YAML front matter"
        Write-Host $mdPath
        Write-Host
        continue
    }

    #
    # Make sure the first property is the title
    #
    if ($content[1] -notmatch "^title: ") {
        $foundProblems++
        Write-Warning "Title must be first in front matter by convention"
        Write-Host $mdPath
        Write-Host
    }
    
    #
    # Parse the YAML front matter
    #
    try {
        $yaml = $content[1..($endOfYaml - 1)] | ConvertFrom-Yaml
    }
    catch {
        $foundProblems++
        Write-Warning "Error parsing YAML front matter"
        Write-Host $mdPath
        Write-Host
        continue
    }

    #
    # Check if the title has already been loaded
    #
    if ($titles.ContainsKey($yaml.title)) {
        $foundProblems++
        Write-Warning "Duplicate title"
        Write-Host $mdPath
        Write-Host 
    }

    #
    # Add the YAML object to the hashtable of pages using its title as key
    #
    $titles[$yaml.title] = $yaml
    $titles[$yaml.title]."::path" = $mdPath
        
    #
    # if type = website
    #
    if ($yaml.type -eq "website") {
        #
        # Track websites for easy dereference later
        #
        if ($null -ne $yaml.website) {
            $websites[$yaml.website] = $yaml.title
        }
    }
}

# ========================================================================
# Build titles array
# ========================================================================
#
# Create an array of titles for n-based references. The
# index of each title may change between builds and should not
# be considered stable. However, assuming no titles are changed
# nor new pages added or removed, the indexes will be stable 
# for the rest of the script run.
#
$titleKeys = [string[]]::new($titles.Count)
$titles.Keys.CopyTo($titleKeys, 0)

# ========================================================================
# Decorators
# ------------------------------------------------------------------------
# A decorator is a function that modifies a page object in some way.
# ========================================================================

function Update-RandomPage($page) {
    #
    # Add a link to a random page
    #
    $index = Get-Random -Minimum 0 -Maximum $titleKeys.Length
    $page["random"] = $titleKeys[$index]
}

# ========================================================================
# Tests
# ------------------------------------------------------------------------
# A test is a function that checks whether a page meets a requirement.
# ========================================================================

function Test-TypeRequiresProperty($page, $type, $property) {
    if ($page["type"] -eq $type) {
        if ($null -eq $page[$property]) {
            Write-Warning "$property property is required when type=$type"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
}

function Test-CountryTypeRequiresCountryOf($page) {
    return Test-TypeRequiresProperty $page "country" "country of"
}

function Test-PictureTypeRequiresPicture($page) {
    return Test-TypeRequiresProperty $page "picture", "picture"
}

function Test-RemotePictureRequiresLicenseAndWebsite($page) {
    #
    # Remote Picture Requires License And Website
    #
    # This rule ensures that all remotely hosted pictures are
    # property attributed and linked to the source. The rule does
    # not apply to local pictures.
    #
    $problems = 0

    if ($page["picture"] -like "http*") {
        if ($null -eq $page["license"]) {
            $problems++
            Write-Warning "license is required for remote picture"
            Write-Host $page["::path"]
            Write-Host
        }
        if ($null -eq $page["website"]) {
            $problems++
            Write-Warning "website is required for remote picture"
            Write-Host $page["::path"]
            Write-Host
        }
    }

    return $problems
}

function Test-UrlMustStartAndEndWithSlash($page) {

    if ($null -ne $page["url"]) {
        if ($page["url"] -notmatch "^/.*?/$") {
            Write-Warning "url property must start and end with a forward slash"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
}

function Test-WebsiteTypeRequiresUrl($page) {
    return Test-TypeRequiresProperty $page "website", "url"
}

function Test-WebsiteTypeRequiresWebsite($page) {
    return Test-TypeRequiresProperty $page "website", "website"
}

#
# Execute decorators first
#
foreach ($page in $titles.Values) {
    Update-RandomPage $page
}

#
# Execute tests after all decorators have run
#
foreach ($page in $titles.Values) {
    $foundProblems += Test-CountryTypeRequiresCountryOf($page)
    $foundProblems += Test-PictureTypeRequiresPicture($page)
    $foundProblems += Test-RemotePictureRequiresLicenseAndWebsite($page)
    $foundProblems += Test-UrlMustStartAndEndWithSlash($page)
    $foundProblems += Test-WebsiteTypeRequiresUrl($page)
    $foundProblems += Test-WebsiteTypeRequiresWebsite($page)
}

#
# Reverse-reference 'of' properties
#
foreach($page in $titles.Values) {

    #
    # Loop through each property of the page and look for ones that end in ' of'
    #
    foreach($propkey in $page.Keys) {
        if ($propkey -like "* of") {
            #$propval = $page[$propkey]
            #if ($titles.ContainsKey($propval)) {
                #$ofPage = $titles[$propval]
                #if ($null -eq $ofPage.of) {
                #    $ofPage.of = [string[]]::new()
                #}
                #$ofPage.of += $page.title
            #}
            #else {
            #    $foundProblems++
            #    Write-Warning "Property '$propkey' references non-existent title '$propval'"
            #    Write-Host $page["::path"]
            #    Write-Host
            #}
        }
    }
}

# ========================================================================
# Save data files
# ========================================================================
#
# Create the data directory if it does not exist
#
$dataPath = Join-Path -Path $rootPath -ChildPath "data"
if (-not (Test-Path -Path $dataPath)) {
    New-Item -ItemType Directory -Path $dataPath | Out-Null
}

#
# Write the $titles hastable to a file in JSON
#
$titles | ConvertTo-Json | Set-Content -Path "$rootPath\data\titles.json"

#
# Write the $websites hashtable to a file in JSON
#
$websites | ConvertTo-Json | Set-Content -Path "$rootPath\data\websites.json"

# ========================================================================
# Summarize results
# ========================================================================

if ($foundProblems -gt 0) {
    Write-Host "$($foundProblems) problems found." `
         -ForegroundColor White `
         -BackgroundColor Red
    Write-Host "In VSCode, ctrl+click the file path to open."
}
else {
    Write-Host "No problem(s) found." `
        -ForegroundColor White `
        -BackgroundColor Green
    Write-Host "Testing can only prove the presence of bugs, not their absence."
    Write-Host "  - Edsger W. Dijkstra"
}

Write-Host "Total pages: $($titles.count)"