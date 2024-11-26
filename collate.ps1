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
        #
        # The property is not defined yet. Add the value.
        #
        $page[$property] = $value
    } else {
        #
        # The property is already defined. Append to an array.
        #
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
# Track the total number of warnings or issues found.
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
# Get-FrontMatter
# ------------------------------------------------------------------------
# Gets a hashtable of the front matter for the specified file.
# ========================================================================

function Get-FrontMatter($file) {

    #
    # Get the relative path of the file for output
    #
    $path = $file.FullName -replace [regex]::Escape($PSScriptRoot + "\"), ''
    
    #
    # Check for a common error of a directory with a .md extension
    #
    if ($file.Attributes -band [System.IO.FileAttributes]::Directory) {
        Debug-Path $path "Directory has .md extension (probably a copy-paste error)"
        return $null
    }
    
    #
    # Skip files called README.md
    #
    if ($file.Name -eq "README.md") {
        return $null
    }
    
    #
    # Get the contents of the file as a string array
    #
    $content = Get-Content -Path $file.FullName
    
    #
    # Make sure the file isn't empty
    #
    if ($null -eq $content) {
        Debug-Path $path "No content loaded"
        return $null
    }
    
    #
    # Make sure the first line is the start of YAML front matter (---)
    #
    if ($content[0] -ne "---") {
        Debug-Path $path "First line must be --- to start YAML front matter"
        return $null
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
        Debug-Path $path "No end of YAML front matter"
        return $null
    }
    
    #
    # Make sure the first property is the title
    #
    if ($content[1] -notmatch "^title: ") {
        Debug-Path $path "Title should be first in front matter by convention"
    }
        
    #
    # Parse the YAML front matter
    #
    try {
        $yaml = $content[1..($endOfYaml - 1)] | ConvertFrom-Yaml
    }
    catch {
        Debug-Path $path "Error parsing YAML front matter"
        return $null
    }
    
    #
    # Skip files where draft is true
    #
    if ($yaml.draft -eq $true) {
        return $null
    }
    
    #
    # Save the path for later reference. By convention, properties
    # defined by the script use a "::" prefix to avoid conflicts
    # with user properties.
    #
    $yaml."::path" = $path
        
    #
    # Adjust the path if it starts with "content\"
    #
    if ($path -like "content\*") {
        $yaml."::content" = $path.Substring(8) -replace '\\', '/'
    }

    return $yaml
}

# ========================================================================
# Get-Lookup
# ------------------------------------------------------------------------
# Generates a hashtable that maps titles to page indexes. It accepts
# an array or arraylist and returns a case-sensitive hashtable where the
# key is a page title, and the value is the integer page index.
# ========================================================================

function Get-Lookup($pages) {

    $hash = [hashtable]::new()
    $index = -1;

    foreach($page in $pages) {

        #
        # Track the 0-based index of this item
        #
        $index++;

        if ($null -eq $page.title) {
            Debug-Page $page "missing title"
        }
        else {
            #
            # Set the index of the title
            #
            $hash[$page.title] = $index

            #
            # Set the index of the lowercase variation of the title
            #
            $lowercaseTitle = $page.title.ToLower()
            if ($lowercaseTitle -cne $page.title) {
                $hash[$lowercaseTitle] = $index
            }    
        }

        #
        # if type = website, add the website address to the lookup
        #
        #if ($page.type -eq "website") {
        #    if ($null -ne $page.website) {
        #        $hash[$page.website] = $index
        #    }
        #}
    }

    return $hash
}

# ========================================================================
# Get-Pages
# ------------------------------------------------------------------------
# Loads the page objects of the specified file system objects. Each
# page object is a hashtable containing the front matter properties. The
# return value is an array of hashtables.
# ========================================================================

function Get-Pages {

    $count = 0
    $lastProgress = -1
    $list = New-Object -TypeName System.Collections.ArrayList

    $mdFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.md" -Recurse
    foreach ($mdFile in $mdFiles) {

        $count++

        #
        # Calculate the progress (percent done) of the files
        #
        $progress = [math]::Round(($count / $mdFiles.Count) * 100)
        if ($progress -ne $lastProgress) {
            $lastProgress = $progress
            Write-Progress -Activity "Loading" -Status $mdFile -PercentComplete $progress
        }
     
        $fm = Get-FrontMatter $mdFile
        if ($null -ne $fm) {
            #$fm.GetType()
            $idx=$list.Add($fm)
        }
    }
    
    Write-Progress -Activity "Loading" -Completed
    return $list.ToArray()
}

# ========================================================================
# Get-Props
# ------------------------------------------------------------------------
# This function generates a hashtable of properties. The input is an
# array of page objects. The output is a hashtable where the key is the
# property name and the value is a hashtable of distinct values for that
# property. The inner hashtable has the distinct value as the key and an
# array of page titles as the value.
# ========================================================================
function Get-Props($pages) {

    $props = [hashtable]::new()

    foreach($page in $pages) {

        foreach($key in $page.Keys) {

            #
            # Create the hashtable for this key.
            #
            if (-not $props.ContainsKey($key)) {
                $props[$key] = [hashtable]::new()
            }

            #
            # Get the key value as an array
            #
            $value = $page[$key]
            if ($value -isnot [array]) {
                $value = @($value)
            }

            foreach($v in $value) {
                if ($null -eq $v) {
                    Debug-Page $page "Property '$key' has a null value"
                    continue
                }
            
                if ($v -isnot [string]) {
                    $v = [string]$v
                    continue
                }
                Add-PropertyValue $props[$key] $v $page["title"]
            }
        }
    }
    return $props
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

#
# Load the front matter of the files
#
$script:pages = Get-Pages

#
# Build a hashtable for looking up pages by title or website url
#
Write-Host "$(Get-EmojiRunning) Indexing titles..."
$script:lookup = Get-Lookup $script:pages

Write-Host "Indexing properties..."
$script:props = Get-Props $script:pages
Write-Host "There are $($script:props.Count) distinct properties."

# ========================================================================
# Updaters
# ------------------------------------------------------------------------
# An updater is a function that modifies a page object in some way.
# ========================================================================

function Update-OfProperties($page, $suffix = "of") {

    #
    # Loop through each property of the page and look for ones that end in ' of'
    #
    foreach($propkey in $page.Keys) {

        if ($propkey -notlike "* $suffix") {
            continue
        }
            
        #
        # Get the property value as an array
        #
        $proparray = $page[$propkey]
        if ($proparray -isnot [array]) {
            $proparray = @($proparray)
        }

        foreach($propvalue in $proparray) {

            if ($null -eq $propvalue) {
                Debug-Page $page "Property '$propkey' has a null value"
                continue
            }

            #
            # Get the index of the page referenced by this value.
            #
            $propindex = $script:lookup[$propvalue]

            #
            # If the index is valid...
            #
            if ($null -ne $propindex) {

                #
                # Get the page at the index
                #
                $ofPage = $script:pages[$propindex]
                if($ofPage -eq $page) {
                    Debug-Page $page "Property '$propkey' references itself"
                    continue
                }

                #
                # Build the name of the property that will be
                # added to the referenced page. To do this, trim
                # off the suffix and extra space, e.g., " of".
                #
                $propertyName = $propkey.Substring( `
                  0, `
                  $propkey.Length - $suffix.Length - 1)

                Add-PropertyValue $ofPage $propertyName $page.title

            }
            else {
                #
                # The index does not exist. This is OK if the 
                # value is a hyperlink. Otherwise issue a warning.
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

function Update-Ofs() {
    Write-Host "$(Get-EmojiRepeat) Of..."
    foreach($page in $script:pages) {
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

    # fine all pages that have the same when value
    $sameWhen = @()
    foreach($other in $script:pages) {

        if ($page -eq $other) {
            #
            # skip this page
            #
            continue
        }

        if ($other["when"] -eq $when) {
            $sameWhen += $other["title"]
        }
    }

    # only if $sameWhen is not empty
    if ($sameWhen.Count -gt 0) {
        $page["on this day"] = $sameWhen
    }
}

function Update-OnTheseDays() {
    Write-Host "$(Get-EmojiCalendar) On these days..."
    foreach($page in $script:pages) {
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
        # Get the index of the page that defines this property
        #
        $propindex = $script:lookup[$propkey]
        if ($null -eq $propindex) {
            continue
        }

        #
        # Get the page for this property and skip if it doesn't exist.
        #
        $proppage = $script:pages[$propindex]
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
    foreach($page in $script:pages) {
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
        $index = Get-Random -Minimum 0 -Maximum $script:pages.Length
        $randomPage = $script:pages[$index]
        $isolated = $randomPage["tags"] -contains "isolated page"
    } while ($isolated)

    $page["random"] = $randomPage["title"]
}

function Update-Randoms() {
    Write-Host "$(Get-EmojiQuestionMark) Randomize..."
    foreach($page in $script:pages) {
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

    #
    # Get the hashtable for tags
    #
    $tags = $script:props["tags"]
    if ($null -eq $tags) {
        Debug-Page $page "No tags property"
        exit
        return
    }

    #
    # Get the titles of all pages that tag this page
    #
    $tagged = $tags[$page.title]
    if ($null -eq $tagged) {
        return
    }
    else {
        $page["tagged"] = $tagged
    }
}

function Update-ReverseTags() {
    Write-Host "$(Get-EmojiBookmark) Reverse tags..."
    foreach($page in $script:pages) {
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

        $timelineIndex = $script:lookup[$title]
        if ($null -eq $timelineIndex) {
            Debug-Page $page "Timeline references non-existent '$title'"
            return
        }

        $timelinePage = $script:pages[$timelineIndex]

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
    foreach($page in $script:pages) {
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
    # Get the wikipedia value
    #
    $wikipedia = $page["wikipedia"]
    if ($null -eq $wikipedia) {
        return
    }

    #
    # Get the index of the wikipedia value
    #
    $wikipediaIndex = $script:lookup[$wikipedia]
    if ($null -eq $wikipediaIndex) {
        return
    }

    # 
    # Get the wikipedia page
    #
    $wikipediaPage = $script:pages[$wikipediaIndex]
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
    foreach($page in $script:pages) {
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

    #
    # See if the property exists as required
    #
    if ($null -ne $page[$property]) {
        return
    }

    #
    # The property doesn't exist, but its plural might,
    # or the page might have a tag to override the requirement.
    # First get the index of the property definition.
    #
    $propertyIndex = $script:lookup[$property]
    if ($null -ne $propertyIndex) {

        #
        # This property has a page at the specified index.
        #
        $propertyPage = $script:pages[$propertyIndex]

        #
        # See if this property has a plural form, and if so,
        # check if the plural form exists on the page.
        #
        $plural = $propertyPage["plural"]
        if ($null -ne $plural) {
            #
            # This property does have a plural form. See if it
            # exists on the page. If the plural form is used,
            # that meets the requirement of existing.
            if ($null -ne $page[$plural]) {
                return
            }
        }

        #
        # Neither the property or its plural form is used on
        # this page. Lastly, see if this property has a tag
        # that overrides the requirement. For example, a 
        # person page requires a Wikipedia article, unless
        # the page uses the tag "no Wikipedia article"
        $nonExistenceTag = $propertyPage["non-existence tag"]
        if ($null -ne $nonExistenceTag) {
            if ($page["tags"] -contains $nonExistenceTag) {
                return
            }
        }
    }

    #
    # All checks failed -- the required property does not exist in any form.
    #
    Debug-Page $page $message
}

function Test-PropertyRequiresTag($page, $property, $tag) {
    #
    # If the page has the given property, it must also
    # contain the given tag in the tags property.
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
    foreach($page in $script:pages) {
        if ($null -ne $page["url"]) {
            $url = $page["url"]
            $urlPages = $script:props["url"][$url]
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

foreach ($page in $script:pages) {
    
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
    Test-TagRequiresProperty $page "bay" "wikidata"
    Test-TagRequiresProperty $page "bay" "Wikipedia"

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

    # dam
    Test-TagRequiresProperty $page "dam" "dam of"
    Test-TagRequiresProperty $page "dam" "openstreetmap"
    Test-TagRequiresProperty $page "dam" "wikidata"
    Test-TagRequiresProperty $page "dam" "Wikipedia"
    
    # emoji
    Test-TypeRequiresProperty $page "emoji" "emoji of"

    # excerpt
    Test-ExcerptCannotHaveFootnotes($page)

    # flag
    Test-TagRequiresProperty $page "flag" "wikipedia"

    # film
    Test-TagRequiresProperty $page "film" "wikidata"
    Test-TagRequiresProperty $page "film" "Wikipedia"

    # hacker news
    Test-PropertyRequiresTag $page "hacker news" "shared on Hacker News"
    Test-TagRequiresProperty $page "shared on Hacker News" "hacker news"    
    
    # human being
    Test-TagRequiresProperty $page "human being" "wikidata"
    Test-TagRequiresProperty $page "human being" "Wikipedia"

    # island
    #Test-PropertyRequiresTag $page "island of" "island"
    Test-TagRequiresProperty $page "island" "island of"
    Test-TagRequiresProperty $page "island" "openstreetmap"
    Test-TagRequiresProperty $page "island" "wikidata"
    Test-TagRequiresProperty $page "island" "wikipedia"

    # lake
    Test-TypeRequiresProperty $page "lake" "lake of"
    Test-TypeRequiresTag $page "lake" "lake"
    Test-TagRequiresProperty $page "lake" "openstreetmap"
    Test-TagRequiresProperty $page "lake" "wikidata"
    Test-TagRequiresProperty $page "lake" "wikipedia"

    # location
    Test-PropertyRequiresTag $page "location of" "location"
    Test-TagRequiresProperty $page "location" "location of"

    # mountain
    Test-TagRequiresProperty $page "mountain" "mountain of"
    Test-TagRequiresProperty $page "mountain" "openstreetmap"
    Test-TagRequiresProperty $page "mountain" "wikidata"
    Test-TagRequiresProperty $page "mountain" "Wikipedia"

    # mountain range
    Test-TagRequiresProperty $page "mountain range" "mountain range of"
    #Test-TagRequiresProperty $page "mountain range" "openstreetmap"
    Test-TagRequiresProperty $page "mountain range" "wikidata"
    Test-TagRequiresProperty $page "mountain range" "Wikipedia"

    # neighborhood
    Test-TagRequiresProperty $page "neighborhood" "neighborhood of"
    Test-TagRequiresProperty $page "neighborhood" "Wikipedia"
    Test-TagRequiresProperty $page "neighborhood" "wikidata"
    
    # park
    Test-TagRequiresProperty $page "park" "openstreetmap"
    
    # picture
    Test-PictureUnderCameraRollRequiresWhen($page)
    Test-RemotePictureRequiresLicenseAndWebsite($page)
    Test-TypeRequiresProperty $page "picture" "picture"

    # photograph
    Test-PropertyRequiresTag $page "photograph of" "photograph"
    Test-TagRequiresProperty $page "photograph" "photograph of"

    # polygon
    Test-TagRequiresProperty $page "polygon" "sides"
    Test-TagRequiresProperty $page "polygon" "wikidata"
    Test-TagRequiresProperty $page "polygon" "Wikipedia"

    # president of the United States
    Test-TagRequiresProperty $page "president of the United States" "birth"
    Test-TagRequiresProperty $page "president of the United States" "member of"
    Test-TagRequiresProperty $page "president of the United States" "portrait"
    Test-TagRequiresProperty $page "president of the United States" "president of"
    Test-TagRequiresProperty $page "president of the United States" "signature"
    Test-TagRequiresProperty $page "president of the United States" "wikidata"
    Test-TagRequiresProperty $page "president of the United States" "Wikipedia"

    # quote
    Test-TypeRequiresTag $page "quote" "quote"
    
    # river
    Test-TypeRequiresTag $page "river" "river"
    Test-TagRequiresProperty $page "river" "openstreetmap"
    Test-TagRequiresProperty $page "river" "river of"
    Test-TagRequiresProperty $page "river" "wikidata"
    Test-TagRequiresProperty $page "river" "Wikipedia"

    # sea
    Test-TagRequiresProperty $page "sea" "sea of"
    Test-TagRequiresProperty $page "sea" "openstreetmap"
    Test-TagRequiresProperty $page "sea" "wikidata"
    Test-TagRequiresProperty $page "sea" "Wikipedia"

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

# ========================================================================
# Save the results
# ========================================================================

$script:pages  | ConvertTo-Json | Set-Content -Path "$rootPath\data\pages.json"
$script:lookup | ConvertTo-Json | Set-Content -Path "$rootPath\data\lookup.json"
$script:props  | ConvertTo-Json | Set-Content -Path "$rootPath\data\props.json"

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

Write-Host "Total pages: $($script:pages.Length)"