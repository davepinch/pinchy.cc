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
$script:foundProblems = 0

function Debug-Page {
    
    param(
        [hashtable]$page,
        [string]$message
    )

    Debug-Path $page["::path"] $message
}

function Debug-Path() {

    param(
        [string]$path,
        [string]$message
    )

    $script:foundProblems++
    Write-Warning "$(Get-EmojiWarning)  $message"

    if ($null -ne $path) {
        #
        # Tip: in VSCode, you can ctrl+click the path to open the file.
        #
        Write-Host $path
        Write-Host
    }
}

# ========================================================================
# Get-Emoji characters
# ========================================================================

function Get-EmojiBookmark() {
    return [System.Char]::ConvertFromUtf32(0x1F516)
}

function Get-EmojiCalendar() {
    return [System.Char]::ConvertFromUtf32(0x1F4C5)
}

function Get-EmojiCheckbox() {
    return [System.Char]::ConvertFromUtf32(0x2611)
    #return Get-EmojiChar("1F5F8")
}

function Get-EmojiGlobe() {
    return [System.Char]::ConvertFromUtf32(0x1F30E)
}

function Get-EmojiLeftRightArrow() {
    return [System.Char]::ConvertFromUtf32(0x2194) + `
           [System.Char]::ConvertFromUtf32(0xFE0F)
}

function Get-EmojiLink() {
    return [System.Char]::ConvertFromUtf32(0x1F517)
}

function Get-EmojiRepeat() {
    return [System.Char]::ConvertFromUtf32(0x1F501)
}

function Get-EmojiRunning() {
    return [System.Char]::ConvertFromUtf32(0x1F3C3)
}

function Get-EmojiOpenFolder() {
    return [System.Char]::ConvertFromUtf32(0x1F4C2)
}

function Get-EmojiQuestionMark() {
    return [System.Char]::ConvertFromUtf32(0x2753)
}

function Get-EmojiTag() {
    return [System.Char]::ConvertFromUtf32(0x1F3F7)
}

function Get-EmojiWarning() {
    return [System.Char]::ConvertFromUtf32(0x26A0) + `
           [System.Char]::ConvertFromUtf32(0xFE0F)
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
Write-Host "$(Get-EmojiOpenFolder) Loading..."
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
$lastProgress = -1

foreach ($mdFile in $mdFiles) {

    #
    # Calculate the progress (percent done) of the files
    #
    $progress = [math]::Round(($titles.Count / $mdFiles.Count) * 100)
    if ($progress -ne $lastProgress) {
        $lastProgress = $progress
        Write-Progress -Activity "Loading" -Status $mdFile -PercentComplete $progress
    }
    #Write-Host "Processing file $processedFiles of $totalFiles ($progress% done)"

 
    #
    # Get the relative path of the file for output
    #
    $mdPath = $mdFile.FullName -replace [regex]::Escape($rootPath + "\"), ''

    #
    # Check for a common error of a directory with a .md extension
    #
    if ($mdFile.Attributes -band [System.IO.FileAttributes]::Directory) {
        Debug-Path $mdPath "Directory has .md extension (probably a copy-paste error)"
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
        Debug-Path $mdPath "No content loaded"
        continue
    }

    #
    # Make sure the first line is the start of YAML front matter (---)
    #
    if ($content[0] -ne "---") {
        Debug-Path $mdPath "First line must be --- to start YAML front matter"
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
        Debug-Path $mdPath "No end of YAML front matter"
        continue
    }

    #
    # Make sure the first property is the title
    #
    if ($content[1] -notmatch "^title: ") {
        Debug-Path $mdPath "Title must be first in front matter by convention"
    }
    
    #
    # Parse the YAML front matter
    #
    try {
        $yaml = $content[1..($endOfYaml - 1)] | ConvertFrom-Yaml
    }
    catch {
        Debug-Path $mdPath "Error parsing YAML front matter"
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
        Debug-Path $mdPath "Title is required"
        continue
    }
    
    #
    # Check if the title has already been loaded
    #
    if ($titles.ContainsKey($yaml.title)) {
        Debug-Path $mdPath "Duplicate title"
    }

    #
    # Add the YAML object to the hashtable of pages using its title as key
    #
    $titles[$yaml.title] = $yaml
    $titles[$yaml.title]."::path" = $mdPath
    
    #
    # Adjust the path if it starts with "content\"
    #
    if ($mdPath -like "content\*") {
        $titles[$yaml.title]."::content" = $mdPath.Substring(8) -replace '\\', '/'
    }

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

Write-Progress -Activity "Loading" -Completed

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
            # Do not use @{} to create a hashtable. That
            # hashtable is not case-sensitive, which causes
            # problems with emoji characters.
            $props[$key] = [hashtable]::new()
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

function Update-Ofs() {
    Write-Host "$(Get-EmojiRepeat) Of..."
    foreach($page in $titles.Values) {
        Update-OfProperties $page
    }
}

# ========================================================================
# Update-OnThisDay
# ------------------------------------------------------------------------
# This function adds an "on this day" property to each page that has a
# "when" property. The "on this day" property is an array of titles that
# have the same "when" value as the current page. The property is not 
# added if it is the ony page with the same "when" value.
# ========================================================================
function Update-OnThisDay($page) {
    # TODO: optimize by caching the when values during load
    $when = $page["when"]
    if ($null -eq $when) {
        return
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
function Update-OnTheseDays() {
    Write-Host "$(Get-EmojiCalendar) On these days..."
    foreach($page in $titles.Values) {
        Update-OnThisDay $page
    }
}

# ========================================================================
# Update-Plural
# ========================================================================
function Update-Plural($page) {

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
            Debug-Page $proppage "plural property must be a string"
            continue
        }

        #
        # Check whether the plural references itself
        #
        if ($plural -eq $propkey) {
            Debug-Page $proppage "plural property should not reference itself"
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
}

function Update-Plurals() {

    $s = [System.Char]::ConvertFromUtf32(0x32) + `
         [System.Char]::ConvertFromUtf32(0xFE0F) + `
         [System.Char]::ConvertFromUtf32(0x20E3)
    Write-Host "$s  Plurals..."
    foreach($page in $titles.Values) {
        Update-Plural $page
    }
}

# ========================================================================
# Update-Random
# ------------------------------------------------------------------------
# This function adds a "random" property to each page. The property 
# contains the title of a random page. Pages with the "isolated page" tag
# are considered sensitive and will not be selected randomly. If a page
# already has a "random" property, it is not changed.
# ========================================================================
function Update-Random($page) {
    #
    # Skip pages that already have an explicit random link.
    #
    if ($null -ne $page["random"]) {
        return
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

function Update-Randoms() {
    Write-Host "$(Get-EmojiQuestionMark) Randomize..."
    foreach($page in $titles.Values) {
        Update-Random $page
    }
}

# ========================================================================
# Update-ReverseTag
# ------------------------------------------------------------------------
# Adds a "tagged" property containing an array of titles that reference
# the current page.
# ========================================================================
function Update-ReverseTag($page) {
    if ($tagged[$page.title] -is [array]) {
        $page["tagged"] = $tagged[$page.title]
    }
}

function Update-ReverseTags() {
    Write-Host "$(Get-EmojiBookmark) Reverse tags..."
    foreach($page in $titles.Values) {
        Update-ReverseTag $page
    }
}

# ========================================================================
# Update-Timeline
# ------------------------------------------------------------------------
# This function updates the timeline property of a page to ensure that
# the pages are ordered by the "when" property. The timeline property
# is an array of titles of pages that are related in time. The function
# will sort the pages by the "when" property and link them together
# with the ➡️ and ⬅️ properties.
# ========================================================================
function Update-Timeline($page) {
    
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

function Update-Timelines() {
    Write-Host "$(Get-EmojiLink) Timelines..."
    foreach($page in $titles.Values) {
        Update-Timeline $page
    }
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
        return
    }

    #
    # Skip if this page does not have a wikipedia property.
    #
    if ($null -eq $page["wikipedia"]) {
        return
    }

    #
    # Skip if the wikipedia value is not a valid title.
    #
    $wikipediaPage = $titles[$page["wikipedia"]]
    if ($null -eq $wikipediaPage) {
        return
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
}

function Update-WikipediaFlagsAndLocations() {
    Write-Host "$(Get-EmojiGlobe) Wikipedia flags and locations..."
    foreach($page in $titles.Values) {
        Update-WikipediaFlagAndLocation $page
    }
}

#
# Execute updaters
#
Update-Ofs
Update-OnTheseDays
Update-Randoms
Update-ReverseTags
Update-Timelines
Update-WikipediaFlagsAndLocations
Update-Plurals

# ========================================================================
# Tests
# ------------------------------------------------------------------------
# A test is a function that checks whether a page meets a requirement.
# ========================================================================

function Test-RequiresProperty($page, $property, $message) {

    if ($null -ne $page[$property]) {
        return
    }

    #
    # The property doesn't exist, but its plural might,
    # or the page might have a tag to override the requirement.
    # First get the property page, which has metadata such
    # as the plural title.
    #
    $propertyPage = $titles[$property]
    if ($null -ne $propertyPage) {

        #
        # See if this property has a plural form, and if so,
        # check if the plural form exists on the page.
        #
        $plural = $propertyPage["plural"]
        if ($null -ne $plural) {

            #
            # The plural title exists
            #
            if ($null -ne $page[$plural]) {
                return
            }
        }

        $nonExistenceTag = $propertyPage["non-existence tag"]
        if ($null -ne $nonExistenceTag) {
            if ($page["tags"] -contains $nonExistenceTag) {
                return
            }
        }
    }

    Debug-Page $page $message
}

function Test-PropertyRequiresTag($page, $property, $tag) {
    #
    # If the page has the given property, it must also
    # contain the given tag in the tags property.
    # Note: this test is not used yet, it is being built for future use.
    #
    if ($null -ne $page[$property]) {
        
        if ($null -eq $page["tags"]) {
            Debug-Page $page "'tags' property is required when '$property' is present"
            return
        }

        if ($page["tags"] -notcontains $tag) {
            Debug-Page $page "'tags' must contain '$tag' when '$property' is present"
            return
        }
    }
}

function Test-TagRequiresProperty($page, $tag, $property) {
    #
    # If the page has the given tag, it must also contain
    # the given property.
    #
    if ($page["tags"] -contains $tag) {
        Test-RequiresProperty `
            $page `
            $property `
            "'$property' property is required when 'tags' contain '$tag'"  
    }
}

function Test-TypeRequiresProperty($page, $type, $property) {
    if ($page["type"] -eq $type) {
        Test-RequiresProperty `
            $page `
            $property `
            "'$property' property is required when type=$type"
    }
}

function Test-TypeRequiresTag($page, $type, $tag) {
    if ($page["type"] -eq $type) {
        if ($null -eq $page["tags"]) {
            Debug-Page $page "'tags' property is required when type=$type"
            return
        }

        if ($page["tags"] -notcontains $tag) {
            Debug-Page $page "'tags' must contain '$tag' when type=$type"
            return
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
            Debug-Page $page "Excerpt cannot contain footnotes"
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
                Debug-Page $page "Pictures in the camera roll requires a 'when' property."
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

    if ($page["picture"] -like "http*") {
        if ($null -eq $page["license"]) {
            Debug-Page $page "license is required for remote picture"
        }
        if ($null -eq $page["website"]) {
            Debug-Page $page "website is required for remote picture"
        }
    }
}

function Test-UniqueUrls() {
    foreach($page in $titles.Values) {
        if ($null -ne $page["url"]) {
            $url = $page["url"]
            $urlPages = $props["url"][$url]
            if ($urlPages.Count -gt 1) {
                Debug-Page $page "URL is not unique"
                foreach($urlPage in $urlPages) {
                    Write-Host "  $urlPage"
                }
            }
        }
    }
}

function Test-UrlCannotHaveFileNamespace($page) {
    #
    # The URL cannot contain "File:" as this is a MediaWiki namespace.
    #
    if ($null -ne $page["url"]) {
        if ($page["url"] -like "*File:*") {
            Debug-Page $page "url property cannot contain 'File:'"
        }
    }
}

function Test-UrlMustStartAndEndWithSlash($page) {
    if ($null -ne $page["url"]) {
        if ($page["url"] -notmatch "^/.*?/$") {
            Debug-Page $page "url property must start and end with a forward slash"
        }
    }
}

#
# Execute tests after all decorators have run
#
Write-Host "Testing..."
Test-UniqueUrls

foreach ($page in $titles.Values) {
    
    # airport
    #$foundProblems += Test-PropertyRequiresTag $page "airport of" "airport"
    Test-TagRequiresProperty $page "airport" "airport of"
    Test-TagRequiresProperty $page "airport" "official website"
    Test-TagRequiresProperty $page "airport" "openstreetmap"
    Test-TagRequiresProperty $page "airport" "wikidata"
    Test-TagRequiresProperty $page "airport" "wikipedia"

    # bay
    Test-TagRequiresProperty $page "bay" "bay of"
    Test-TagRequiresProperty $page "bay" "openstreetmap"
    Test-TagRequiresProperty $page "bay" "wikipedia"

    # building
    Test-TagRequiresProperty $page "building" "building of"
    Test-TagRequiresProperty $page "building" "openstreetmap"
    Test-TagRequiresProperty $page "building" "wikidata"
    Test-TagRequiresProperty $page "building" "Wikipedia"
    
    # chemical element
    Test-TypeRequiresTag $page "element" "chemical element"
    Test-TagRequiresProperty $page "chemical element" "wikidata"
    Test-TagRequiresProperty $page "chemical element" "wikipedia"

    # city
    Test-TagRequiresProperty $page "city" "city of"
    Test-TagRequiresProperty $page "city" "openstreetmap"
    Test-TagRequiresProperty $page "city" "wikidata"
    Test-TagRequiresProperty $page "city" "wikipedia"

    # country
    Test-TypeRequiresTag $page "country" "country"
    Test-TagRequiresProperty $page "country" "country of"
    Test-TagRequiresProperty $page "country" "flag"
    Test-TagRequiresProperty $page "country" "location"
    Test-TagRequiresProperty $page "country" "openstreetmap"
    Test-TagRequiresProperty $page "country" "wikidata"
    Test-TagRequiresProperty $page "country" "wikipedia"

    # county
    Test-TypeRequiresTag $page "county" "county"
    Test-TagRequiresProperty $page "county" "county of"
    Test-TagRequiresProperty $page "county" "county of"
    Test-TagRequiresProperty $page "county" "openstreetmap"
    Test-TagRequiresProperty $page "county" "wikidata"
    Test-TagRequiresProperty $page "county" "wikipedia"

    # emoji
    Test-TypeRequiresProperty $page "emoji" "emoji of"

    # excerpt
    Test-ExcerptCannotHaveFootnotes($page)

    # flag
    Test-TagRequiresProperty $page "flag" "wikipedia"

    # hacker news
    Test-PropertyRequiresTag $page "hacker news" "shared on Hacker News"
    Test-TagRequiresProperty $page "shared on Hacker News" "hacker news"    
    
    # lake
    Test-TypeRequiresProperty $page "lake" "lake of"
    Test-TypeRequiresTag $page "lake" "lake"
    Test-TagRequiresProperty $page "lake" "openstreetmap"

    # location
    Test-PropertyRequiresTag $page "location of" "location"
    Test-TagRequiresProperty $page "location" "location of"

    # park
    Test-TagRequiresProperty $page "park" "openstreetmap"
    
    # picture
    Test-PictureUnderCameraRollRequiresWhen($page)
    Test-RemotePictureRequiresLicenseAndWebsite($page)
    Test-TypeRequiresProperty $page "picture" "picture"

    # photograph
    Test-PropertyRequiresTag $page "photograph of" "photograph"
    Test-TagRequiresProperty $page "photograph" "photograph of"

    # quote
    Test-TypeRequiresTag $page "quote" "quote"
    
    # river
    Test-TypeRequiresProperty $page "river" "river of"
    Test-TypeRequiresProperty $page "river" "wikipedia"
    Test-TypeRequiresTag $page "river" "river"

    # snippet
    Test-TypeRequiresTag $page "snippet" "snippet"
    Test-TypeRequiresProperty $page "snippet", "url"

    # star
    Test-TypeRequiresProperty $page "star" "star of"
    
    # url
    Test-UrlCannotHaveFileNamespace($page)
    Test-UrlMustStartAndEndWithSlash($page)

    # website
    Test-TypeRequiresProperty $page "website" "url"
    Test-TypeRequiresProperty $page "website" "website"

    # wikipedia
    Test-PropertyRequiresTag $page "wikipedia of" "wikipedia"
    Test-TagRequiresProperty $page "wikipedia" "wikipedia of"

    # youtube
    Test-TypeRequiresTag $page "youtube" "YouTube video"
    Test-TagRequiresProperty $page "YouTube video" "url"
    Test-TagRequiresProperty $page "YouTube video" "website"
    Test-TagRequiresProperty $page "YouTube video" "youtube-id"
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

if ($script:foundProblems -gt 0) {
    Write-Host "$($script:foundProblems) problems found." `
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