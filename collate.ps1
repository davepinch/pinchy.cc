
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
    # Make sure content is loaded from the file.
    #
    if ($null -eq $content) {
        $foundProblems++
        Write-Warning "No content loaded"
        Write-Host $mdPath
        Write-Host
        continue
    }

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

    if ($null -eq $yaml.title) {
        $foundProblems++
        Write-Warning "Title is required"
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
                    #
                    # Ignore cases where the the "of" property begins with https://
                    #
                    if ($propvalue -notmatch "^https://") {
                        $problems++
                        Write-Warning "Property '$propkey' references non-existent title '$propvalue'"
                        Write-Host $page["::path"]
                        Write-Host
                    }
                }
            }
        }
    }

    return $problems
}

function Update-TimelineOrder($page) {
    
    #
    # If the page has a timeline property...
    #
    $timeline = $page["timeline"]
    if ($null -eq $timeline) {
        return 0
    }

    if ($timeline -isnot [array]) {
        return 0
    }

    #
    # Loop through the $timeline array and find the page
    # for each title (the array contains titles of pages).
    # Collect these into a list.
    #
    $problems = 0
    $timelinePages = @()
    foreach($title in $timeline) {

        if ($null -eq $title) {
            Write-Warning "timeline array item is null"
            Write-Host $page["::path"]
            Write-Host
            $problems++
            continue
        }

        $timelinePage = $titles[$title]
        if ($null -eq $timelinePage) {
            Write-Warning "Timeline references non-existent '$title'"
            Write-Host $page["::path"]
            Write-Host
            $problems++
            continue
        }

        if ($null -eq $timelinePage["when"]) {
            Write-Warning "Timeline item '$title' has no 'when' property"
            Write-Host $page["::path"]
            Write-Host
            $problems++
            continue
        }

        $timelinePages += $timelinePage
    }

    if ($problems -gt 0) {
        return $problems
    }    

    #
    # Sort the objects by the "when" property
    #
    $sortedPages = $timelinePages | Sort-Object { $_."when" }

    #
    # Link next/previous pages together
    #
    for ($i = 0; $i -lt $sortedPages.Count; $i++) {
        $p = $sortedPages[$i]
        
        if ($i -lt $sortedPages.Count - 1) {
            $p["➡️"] = $sortedPages[$i+1].title
        }

        if ($i -gt 0) {
            $p["⬅️"] = $sortedPages[$i-1].title
        }
    }

    #
    # Convert to an array of titles
    #
    $timeline = @()
    foreach($timelinePage in $sortedPages) {
        $timeline += $timelinePage.title
    }
    $page["timeline"] = $timeline
}

#
# Execute decorators
#
foreach ($page in $titles.Values) {
    #
    # Other decorators depend on this one
    #
    $foundProblems += Update-OfProperties $page
}

foreach($page in $titles.Values) {
    $foundProblems += Update-RandomPage $page
}

foreach($page in $titles.Values) {
    #
    # Depends on Update-OfProperties
    #
    $foundProblems += Update-TimelineOrder $page
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

function Test-TagRequiresProperty($page, $tag, $property) {
    #
    # If the page has the given tag, it must also contain
    # the given property.
    #
    if ($page["tags"] -contains $tag) {
        if ($null -eq $page[$property]) {
            Write-Warning "$property property is required when tags contain '$tag'"
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

function Test-TypeRequiresTag($page, $type, $tag) {
    if ($page["type"] -eq $type) {
        if ($null -eq $page["tags"]) {
            Write-Warning "tags property is required when type=$type"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }

        if ($page["tags"] -notcontains $tag) {
            Write-Warning "tags must contain '$tag' when type=$type"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
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

function Test-PictureUnderCameraRollRequiresWhen($page) {
    #
    # If the type is picture, and the picture property specifies a
    # a string under content/camera-roll/, then a "when" property is
    # required.
    #
    if ($page["type"] -eq "picture") {
        if ($page["picture"] -like "content/camera-roll/*") {
            if ($null -eq $page["when"]) {
                Write-Warning "Pictures in the camera roll requires a 'when' property."
                Write-Host $page["::path"]
                Write-Host
                return 1
            }
        }
    }
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

function Test-UrlCannotHaveFileNamespace($page) {
    #
    # The URL cannot contain "File:" as this is a MediaWiki namespace.
    #
    if ($null -ne $page["url"]) {
        if ($page["url"] -like "*File:*") {
            Write-Warning "url property cannot contain 'File:'"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
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

#
# Execute tests after all decorators have run
#
foreach ($page in $titles.Values) {
    
    # country
    $foundProblems += Test-TypeRequiresProperty $page "country" "country of"
    $foundProblems += Test-TypeRequiresProperty $page "country" "wikipedia"
    $foundProblems += Test-TypeRequiresTag $page "country" "country"

    # county
    $foundProblems += Test-TypeRequiresProperty $page "county" "county of"
    $foundProblems += Test-TypeRequiresProperty $page "county" "wikipedia"
    $foundProblems += Test-TypeRequiresTag $page "county" "county"

    # emoji
    $foundProblems += Test-TypeRequiresProperty $page "emoji" "emoji of"

    # excerpt
    $foundProblems += Test-ExcerptCannotHaveFootnotes($page)

    # lake
    $foundProblems += Test-TypeRequiresProperty $page "lake" "lake of"
    $foundProblems += Test-TypeRequiresTag $page "lake" "lake"

    # picture
    $foundProblems += Test-PictureUnderCameraRollRequiresWhen($page)
    $foundProblems += Test-RemotePictureRequiresLicenseAndWebsite($page)
    $foundProblems += Test-TypeRequiresProperty $page "picture" "picture"

    # quote
    $foundProblems += Test-TypeRequiresTag $page "quote" "quote"
    
    # river
    $foundProblems += Test-TypeRequiresProperty $page "river" "river of"
    $foundProblems += Test-TypeRequiresProperty $page "river" "wikipedia"
    $foundProblems += Test-TypeRequiresTag $page "river" "river"

    # snippet
    $foundProblems += Test-TypeRequiresTag $page "snippet" "snippet"
    $foundProblems += Test-TypeRequiresProperty $page "snippet", "url"

    # star
    $foundProblems += Test-TypeRequiresProperty $page "star" "star of"
    
    # url
    $foundProblems += Test-UrlCannotHaveFileNamespace($page)
    $foundProblems += Test-UrlMustStartAndEndWithSlash($page)

    # website
    $foundProblems += Test-TypeRequiresProperty $page "website" "url"
    $foundProblems += Test-TypeRequiresProperty $page "website" "website"

    # wikipedia
    $foundProblems += Test-PropertyRequiresTag $page "wikipedia of" "wikipedia"
    $foundProblems += Test-TagRequiresProperty $page "wikipedia" "wikipedia of"
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