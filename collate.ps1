
# =======================================================================
# Add-PropertyValue
# -----------------------------------------------------------------------
# This function adds a value to a property of a page object. If the 
# property does not exist, it is created with the specified value. If
# the property already exists, the value is appended to the property
# as an array.
# =======================================================================

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

# =======================================================================
# Debug-Page
# -----------------------------------------------------------------------
# This function writes a warning message and keeps track of the various
# issues found in the markdown files.
# =======================================================================

#
# Track the number of warnings or issues found.
#
$foundProblems = 0

function Debug-Page($page, $message) {
    
    $foundProblems++
    Write-Warning $message

    if ($null -ne $page["::path"]) {
        #
        # Tip: in VSCode, you can ctrl+click the path to open the file.
        #
        Write-Host $page["::path"]
        Write-Host
    }
}

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
    exit
}

# ========================================================================
# Load *.md files
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

#
# Define a hashtable of reverse-tags
#
$tagged = [hashtable]::new()

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

    #
    # Skip files where draft is true
    #
    if ($yaml.draft -eq $true) {
        continue
    }

    #
    # Check for missing title
    #
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

    if ($null -ne $yaml["tags"]) {
        if ($yaml["tags"] -isnot [array]) {
            $yaml["tags"] = @($yaml["tags"])
        }
    }
    
    if ($yaml["tags"] -is [array]) {
        foreach($tag in $yaml["tags"]) {
            if (-not $tagged.ContainsKey($tag)) {
                $tagged[$tag] = @()
            }
            $tagged[$tag] += $yaml.title
        }
    }

}

# ========================================================================
# $props
# ------------------------------------------------------------------------
# The $props hashtable contains a key for each distinct property used in
# any page. For example, it contains a "title" and a "tags" as these are
# commonly used keys. The value of each key is also a hashtable. The keys
# of the inner hashtable are the distinct values of the property.
# ========================================================================

$props = [hashtable]::new()

Write-Host "Building props hashtable..."

foreach($page in $titles.Values) {
    foreach($key in $page.Keys) {

        if (-not $props.ContainsKey($key)) {
            $props[$key] = @{}
        }

        $value = $page[$key]
        if ($null -eq $value) {
            Debug-Page $page "Property '$key' is null"
            continue
        }

        if ($value -is [array]) {
            foreach($v in $value) {
                if ($null -eq $v) {
                    Debug-Page $page "Property '$key' has a null value"
                    continue
                }
                Add-PropertyValue $props[$key] $v $page["title"]
            }
        }
        else {
            Add-PropertyValue $props[$key] $value $page["title"]
        }
    }
}

Write-Host "There are $($props.Count) distinct properties."

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
# Updaters
# ------------------------------------------------------------------------
# An updater is a function that modifies a page object in some way.
# ========================================================================

function Update-OfProperties($page) {

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
                    Debug-Page $page "Property '$propkey' has a null value"
                    continue
                }

                if ($titles.ContainsKey($propvalue)) {

                    #
                    # Calculate the name of the property to set
                    #
                    $ofPage = $titles[$propvalue]
                    if($ofPage -eq $page) {
                        Debug-Page $page "Property '$propkey' references itself"
                        continue
                    }

                    # 
                    # Remove the " of" suffix from the property name
                    #
                    $propertyName = $propkey.Substring(0, $propkey.Length - 3)
                    Add-PropertyValue $ofPage $propertyName $page.title

                }
                else {
                    #
                    # Ignore cases where the the "of" property begins with http
                    #
                    if ($propvalue -notmatch "^https?://") {
                        Debug-Page `
                            $page `
                            "Property '$propkey' references non-existent title '$propvalue'"
                    }
                }
            }
        }
    }
}

function Update-OnThisDay($page) {
    # TODO: optimize by caching the when values during load
    $when = $page["when"]
    if ($null -eq $when) {
        return 0
    }

    # fine all titles that have the same when value
    $sameWhen = @()
    foreach($title in $titles.Keys) {

        if ($title -eq $page.title) {
            #
            # skip this page
            #
            continue
        }

        if ($titles[$title]["when"] -eq $when) {
            $sameWhen += $title
        }
    }

    # only if $sameWhen is not empty
    if ($sameWhen.Count -gt 0) {
        $page["on this day"] = $sameWhen
    }
}

function Update-PluralProperties($page) {

    $problems = 0

    #
    # Get a copy of the keys as an array that will
    # not change if the hashtable itself is changed.
    # The Keys property is an ICollection that changes
    # as the hashtable is modified. Therefore the keys
    # cannot be modified during enumeration.
    $keys = [string[]]::new($page.Keys.Count)
    $page.Keys.CopyTo($keys, 0)

    #
    # Loop through each property of the page
    #    
    foreach($propkey in $keys) {

        #
        # Get the page for this property and skip if it doesn't exist.
        #
        $proppage = $titles[$propkey]
        if ($null -eq $proppage) {
            continue
        }

        #
        # Check for a plural string of the property
        #
        $plural = $proppage["plural"]
        if ($null -eq $plural) {
            continue
        }

        #
        # Only string-type values are supported
        #
        if ($plural -isnot [string]) {
            $problems++
            Write-Warning "plural property must be a string"
            Write-Host $proppage["::path"]
            continue
        }

        #
        # Check whether the plural references itself
        #
        if ($plural -eq $propkey) {
            $problems++
            Write-Warning "plural property should not reference itself"
            Write-Host $proppage["::path"]
            continue
        }

        #
        # Get the plural property
        #
        $pluralprop = $page[$plural]
        if ($null -eq $pluralprop) {
            
            # The plural property does not exist. If the
            # singular property ($propkey) is an array of
            # length 2 or more, then the singular property
            # should be renamed to the plural property.

            if ($page[$propkey] -is [array] -and $page[$propkey].Length -ge 2) {
                $page[$plural] = $page[$propkey]

                # Remove the singular property.
                $page.Remove($propkey)
            }

            continue
        }
        else {
            #
            # Ensure the plural property is an array.
            #
            if ($pluralprop -isnot [array]) {
                $pluralprop = @($pluralprop)
            }

            #
            # Get the "singular" value as an array
            #
            $propvalue = $page[$propkey]
            if ($propvalue -isnot [array]) {
                $propvalue = @($propvalue)
            }

            #
            # Add the singular values to the plural property
            #
            foreach($value in $propvalue) {
                $pluralprop += $value
            }

            #
            # Save the plural array and remove the singular property
            #
            $page[$plural] = $pluralprop
            $page.Remove($propkey)
        }
    }

    return $problems
}

# ========================================================================
# Update-RandomPages
# ------------------------------------------------------------------------
# This function adds a "random" property to each page. The property 
# contains the title of a random page. Pages with the "isolated page" tag
# are considered sensitive and will not be selected randomly. If a page
# already has a "random" property, it is not changed.
# ========================================================================
function Update-RandomPages() {
    foreach($page in $titles.Values) {
        #
        # Skip pages that already have an explicit random link.
        #
        if ($null -ne $page["random"]) {
            continue
        }

        #
        # Skip isolated pages
        #
        do {
            $index = Get-Random -Minimum 0 -Maximum $titleKeys.Length
            $randomPage = $titles[$titleKeys[$index]]
            $isolated = $randomPage["tags"] -contains "isolated page"
        } while ($isolated)

        $page["random"] = $randomPage["title"]
    }
}

function Update-Tagged($page) {
    if ($tagged[$page.title] -is [array]) {
        $page["tagged"] = $tagged[$page.title]
    }
}

# ========================================================================
# Update-TimelineOrder
# ------------------------------------------------------------------------
# This function updates the timeline property of a page to ensure that
# the pages are ordered by the "when" property. The timeline property
# is an array of titles of pages that are related in time. The function
# will sort the pages by the "when" property and link them together
# with the ➡️ and ⬅️ properties.
# ========================================================================
function Update-TimelineOrder($page) {
    
    #
    # If the page has a timeline property...
    #
    $timeline = $page["timeline"]
    if ($null -eq $timeline) {
        return
    }

    if ($timeline -isnot [array]) {
        return
    }

    #
    # Loop through the $timeline array and find the page
    # for each title (the array contains titles of pages).
    # Collect these into a list.
    #
    $timelinePages = @()
    foreach($title in $timeline) {

        if ($null -eq $title) {
            Debug-Page $page "timeline array item is null"
            return
        }

        $timelinePage = $titles[$title]
        if ($null -eq $timelinePage) {
            Debug-Page $page "Timeline references non-existent '$title'"
            return
        }

        if ($null -eq $timelinePage["when"]) {
            Debug-Page $page "Timeline item '$title' has no 'when' property"
            return
        }

        $timelinePages += $timelinePage
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

function Update-TimelineOrders() {
    Write-Host "Updating timeline orders..."
    foreach($page in $titles.Values) {
        Update-TimelineOrder $page
    }
    Write-Host "Timeline orders updated."
} 

# ========================================================================
# Update-WikipediaFlagAndLocation
# ------------------------------------------------------------------------
# This function updates the wikipedia article associated with certain
# pages (country, state, etc.) with the flag and location properties
# from the page.
# ========================================================================
function Update-WikipediaFlagAndLocation($page) {

    #
    # This function updates the wikipedia article associated
    # with certain pages (country, state, etc.) with the flag
    # and location properties from the page.
    #
    if ($page["tags"] -notcontains "county" -and
        $page["tags"] -notcontains "country" -and
        $page["tags"] -notcontains "city" -and
        $page["tags"] -notcontains "penninsula" -and
        $page["tags"] -notcontains "state" -and
        $page["tags"] -notcontains "province") {
        return 0
    }

    #
    # Skip if this page does not have a wikipedia property.
    #
    if ($null -eq $page["wikipedia"]) {
        return 0
    }

    #
    # Skip if the wikipedia value is not a valid title.
    #
    $wikipediaPage = $titles[$page["wikipedia"]]
    if ($null -eq $wikipediaPage) {
        return 0
    }

    #
    # Copy the flag property over, if it exists on this page.
    #
    if ($null -ne $page["flag"]) {
        Add-PropertyValue $wikipediaPage "flag" $page["flag"]
    }

    # Copy the location property over, if it exists on this page.
    if ($null -ne $page["location"]) {
        Add-PropertyValue $wikipediaPage "location" $page["location"]
    }

    return 0
}

#
# Execute decorators
#
foreach ($page in $titles.Values) {
    #
    # Other decorators depend on this one
    #
    Update-OfProperties $page
}


foreach($page in $titles.Values) {
    $foundProblems += Update-Tagged $page
    $foundProblems += Update-WikipediaFlagAndLocation $page
    $foundProblems += Update-OnThisDay $page
}

Update-RandomPages
Update-TimelineOrders

#
# Normalize singular/plural properties so they make sense.
# This is done after all changes have been applied
#
foreach($page in $titles.Values) {
    $foundProblems += Update-PluralProperties $page
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
            Write-Warning "'tags' property is required when '$property' is present"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }

        if ($page["tags"] -notcontains $tag) {
            Write-Warning "'tags' property must contain '$tag' when '$property' is present"
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
            Write-Warning "'$property' property is required when 'tags' contain '$tag'"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
}

function Test-TypeRequiresProperty($page, $type, $property) {
    if ($page["type"] -eq $type) {
        if ($null -eq $page[$property]) {
            Write-Warning "'$property' property is required when type=$type"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }
    }
}

function Test-TypeRequiresTag($page, $type, $tag) {
    if ($page["type"] -eq $type) {
        if ($null -eq $page["tags"]) {
            Write-Warning "'tags' property is required when type=$type"
            Write-Host $page["::path"]
            Write-Host
            return 1
        }

        if ($page["tags"] -notcontains $tag) {
            Write-Warning "'tags' must contain '$tag' when type=$type"
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
    
    # airport
    #$foundProblems += Test-PropertyRequiresTag $page "airport of" "airport"
    $foundProblems += Test-TagRequiresProperty $page "airport" "airport of"
    $foundProblems += Test-TagRequiresProperty $page "airport" "official website"
    $foundProblems += Test-TagRequiresProperty $page "airport" "openstreetmap"
    $foundProblems += Test-TagRequiresProperty $page "airport" "wikidata"
    $foundProblems += Test-TagRequiresProperty $page "airport" "wikipedia"

    # bay
    $foundProblems += Test-TagRequiresProperty $page "bay" "bay of"
    $foundProblems += Test-TagRequiresProperty $page "bay" "openstreetmap"
    $foundProblems += Test-TagRequiresProperty $page "bay" "wikipedia"

    # city
    $foundProblems += Test-TagRequiresProperty $page "city" "city of"
    $foundProblems += Test-TagRequiresProperty $page "city" "openstreetmap"
    $foundProblems += Test-TagRequiresProperty $page "city" "wikidata"
    $foundProblems += Test-TagRequiresProperty $page "city" "wikipedia"

    # country
    $foundProblems += Test-TypeRequiresProperty $page "country" "country of"
    $foundProblems += Test-TypeRequiresProperty $page "country" "wikipedia"
    $foundProblems += Test-TypeRequiresTag $page "country" "country"

    # county
    $foundProblems += Test-TagRequiresProperty $page "county" "county of"
    $foundProblems += Test-TypeRequiresProperty $page "county" "county of"
    $foundProblems += Test-TypeRequiresProperty $page "county" "openstreetmap"
    $foundProblems += Test-TypeRequiresProperty $page "county" "wikidata"
    $foundProblems += Test-TypeRequiresProperty $page "county" "wikipedia"
    $foundProblems += Test-TypeRequiresTag $page "county" "county"

    # emoji
    $foundProblems += Test-TypeRequiresProperty $page "emoji" "emoji of"

    # excerpt
    $foundProblems += Test-ExcerptCannotHaveFootnotes($page)

    # flag
    $foundProblems += Test-TagRequiresProperty $page "flag" "wikipedia"

    # hacker news
    $foundProblems += Test-PropertyRequiresTag $page "hacker news" "shared on Hacker News"
    $foundProblems += Test-TagRequiresProperty $page "shared on Hacker News" "hacker news"    
    # lake
    $foundProblems += Test-TypeRequiresProperty $page "lake" "lake of"
    $foundProblems += Test-TypeRequiresTag $page "lake" "lake"
    $foundProblems += Test-TagRequiresProperty $page "lake" "openstreetmap"

    # location
    $foundProblems += Test-PropertyRequiresTag $page "location of" "location"
    $foundProblems += Test-TagRequiresProperty $page "location" "location of"

    # park
    $foundProblems += Test-TagRequiresProperty $page "park" "openstreetmap"
    
    # picture
    $foundProblems += Test-PictureUnderCameraRollRequiresWhen($page)
    $foundProblems += Test-RemotePictureRequiresLicenseAndWebsite($page)
    $foundProblems += Test-TypeRequiresProperty $page "picture" "picture"

    # photograph
    $foundProblems += Test-PropertyRequiresTag $page "photograph of" "photograph"
    $foundProblems += Test-TagRequiresProperty $page "photograph" "photograph of"

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

    # youtube
    $foundProblems += Test-TypeRequiresProperty $page "youtube" "youtube-id"
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