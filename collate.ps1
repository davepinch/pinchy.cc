
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

function Add-PropertyValue($page, $property, $value) {

    if (-not $page.ContainsKey($property)) {
        $page[$property] = $value
    } else {
        if ($page[$property] -isnot [array]) {
            $page[$property] = @($page[$property])
        }
        $page[$property] += $value
    }
}

function Update-RandomPage($page) {
    #
    # Add a link to a random page
    #
    $index = Get-Random -Minimum 0 -Maximum $titleKeys.Length
    $page["random"] = $titleKeys[$index]
}

function Update-OfProperties($page) {

    $problems = 0

    #
    # Loop through each property of the page and look for ones that end in ' of'
    #
    foreach($propkey in $page.Keys) {
        if ($propkey -like "* of") {
            
            #
            # Get the property value as an array
            #
            $proparray = $page[$propkey]
            if ($proparray -isnot [array]) {
                $proparray = @($proparray)
            }

            #
            # Confirm each value is a valid title
            #
            foreach($propvalue in $proparray) {

                if ($null -eq $propvalue) {
                    $problems++
                    Write-Warning "Property '$propkey' has a null value"
                    Write-Host $page["::path"]
                    Write-Host
                    continue
                }

                if ($titles.ContainsKey($propvalue)) {

                    #
                    # Calculate the name of the property to set
                    #
                    $ofPage = $titles[$propvalue]
                    if($ofPage -eq $page) {
                        $problems++
                        Write-Warning "Property '$propkey' references itself"
                        Write-Host $page["::path"]
                        Write-Host
                        continue
                    }
                    $propertyName = $propkey -replace " of", ""
                    Add-PropertyValue $ofPage $propertyName $page.title

                }
                else {
                    $problems++
                    Write-Warning "Property '$propkey' references non-existent title '$propvalue'"
                    Write-Host $page["::path"]
                    Write-Host
                }
            }
        }
    }

    return $problems
}

#
# Execute decorators first
#
foreach ($page in $titles.Values) {
    $foundProblems += Update-OfProperties $page
    $foundProblems += Update-RandomPage $page
}

# ========================================================================
# Tests
# ------------------------------------------------------------------------
# A test is a function that checks whether a page meets a requirement.
# ========================================================================

function Test-PropertyRequiresTag($page, $property, $tag) {
    #
    # If the page has the given property, it must also
    # contain the given tag in the tags property.
    # Note: this test is not used yet, it is being built for future use.
    #
    if ($null -ne $page[$property]) {
        
        if ($null -eq $page["tags"]) {
            Write-Warning "tags property is required when $property is present"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }

        if ($page["tags"] -notcontains $tag) {
            Write-Warning "tags property must contain '$tag' when $property is present"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
}

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


function Test-CountyTypeRequiresCountyOf($page) {
    return Test-TypeRequiresProperty $page "county" "county of"
}

function Test-ExcerptCannotHaveFootnotes($page) {
    #
    # The excerpt property cannot contain text that looks like
    # footnote reference such as [1] or [13]. This is often
    # unintentionally copied from Wikipedia.
    #
    if ($null -ne $page["excerpt"]) {
        if ($page["excerpt"] -match "\[\d+\]") {
            Write-Warning "Excerpt cannot contain footnotes"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
}

function Test-LakeTypeRequiresLakeOf($page) {
    return Test-TypeRequiresProperty $page "lake" "lake of"
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

function Test-RiverTypeRequiresRiverOf($page) {
    return Test-TypeRequiresProperty $page "river" "river of"
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
# Execute tests after all decorators have run
#
foreach ($page in $titles.Values) {
    $foundProblems += Test-CountryTypeRequiresCountryOf($page)
    $foundProblems += Test-CountyTypeRequiresCountyOf($page)
    $foundProblems += Test-ExcerptCannotHaveFootnotes($page)
    $foundProblems += Test-LakeTypeRequiresLakeOf($page)
    $foundProblems += Test-PictureTypeRequiresPicture($page)
    $foundProblems += Test-RemotePictureRequiresLicenseAndWebsite($page)
    $foundProblems += Test-RiverTypeRequiresRiverOf($page)
    $foundProblems += Test-UrlMustStartAndEndWithSlash($page)
    $foundProblems += Test-WebsiteTypeRequiresUrl($page)
    $foundProblems += Test-WebsiteTypeRequiresWebsite($page)
}

#
# Reverse-reference 'of' properties
#
foreach($page in $titles.Values) {

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