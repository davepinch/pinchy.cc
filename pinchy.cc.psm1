Function ConvertTo-NormalHTML {

    # https://stackoverflow.com/questions/56187543/invoke-webrequest-freezes-hangs
    param([Parameter(Mandatory = $true, ValueFromPipeline = $true)]$HTML)

    $NormalHTML = New-Object -Com "HTMLFile"
    $NormalHTML.IHTMLDocument2_write($HTML.RawContent)
    return $NormalHTML
}

function Import-CommonsPicture {

    param (
        [string]$url
    )

    #
    # Fetch the content from the URL.
    #
    try {
        $content = Invoke-WebRequest -Uri $url
    } catch {
        Write-Error "Failed to download content from $url. Error: $_"
        return
    }
 
    #
    # Create an array to hold the front matter
    #
    $lines = @()

    #
    # --- (start of front matter)
    #
    $lines += "---"

    #
    # title: "..." (must be enclosed in quotes)
    #
    # The title on Wikimedia Commons has the following format:
    # "File:filename.svg - Wikimedia Commons"
    # Extract the text between File: and - Wikimedia Commons
    $title = $content.ParsedHtml.querySelector("title").innerText
    $title = $title -replace "^File:", ""
    $title = $title -replace " - Wikimedia Commons$", " (Wikimedia Commons)"
    $lines += "title: `"$title`""

    #
    # type: picture
    #
    $lines += "type: picture"

    #
    # url: /path/to/file - but remove the File: namespace in the path
    #
    $localUrl = "/" + ($url -replace "https://", "") + "/"
    $localUrl = $localUrl -replace "/wiki/File:", "/wiki/"
    $lines += "url: $localUrl"

    #
    # website: url
    #
    $lines += "website: `"$url`""

    # tags:
    #   - flag
    #   - Wikimedia Commons
    $lines += "tags:"
    $lines += "  - Wikimedia Commons"

    #
    # --- (end of YAML front matter)
    #
    $lines += "---"

    #
    # Write the content to a file
    #
    $outputPath = "commons.wikimedia.org.md"
    $lines | Out-File -FilePath $outputPath -Encoding utf8
}

function Import-VisibleEarth {

    param (
        [string]$url
    )

    #
    # Fetch the content from the URL.
    #
    try {
        #
        # Note: Invoke-WebRequest is used with -UseBasicParsing
        # to avoid a hang that occurs randomly. For more info, see:
        # https://stackoverflow.com/questions/56187543/invoke-webrequest-freezes-hangs
        #
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    } catch {
        Write-Error "Failed to download content from $url. Error: $_"
        return
    }

    #
    # Manually parse the HTML using the StackOverflow solution.
    #
    $parsed = ConvertTo-NormalHTML -HTML $response 

    #
    # Create an array to hold the front matter
    #
    $lines = @()

    #
    # --- (start of front matter)
    #
    $lines += "---"

    #
    # title: "..." (must be enclosed in quotes)
    #
    $title = $parsed.title
    $lines += "title: `"$title (visibleearth.nasa.gov)`""

    #
    # license: public domain
    #
    $lines += "license: public domain"
    
    #
    # retrieved: yyyy-MM-dd
    #
    $lines += "retrieved: " + (Get-Date -format "yyyy-MM-dd")

    #
    # type: picture
    #
    $lines += "type: picture"

    #
    # url:
    #
    $lines += "url: /" + ($url -replace "https?://", "" )+ "/"

    #
    # website:
    #
    $lines += "website: `"$url`""
    
    #
    # tags:
    #
    $lines += "tags:"
    $lines += "  - satellite imagery"

    #
    # --- (end of front matter)
    #
    $lines += "---"

    #
    # Write the content to a file
    #

    #
    # The website has the format https://visibleearth.nasa.gov/images/12345/image-name
    # where 12345 is a number and image-name is the name of the image.
    # We need to extract the image name from the URL.
    #
    $slug = $url -replace "https?://www.visibleearth\.nasa\.gov/images/\d+/", ""
    $slug = $slug + ".md"
    $lines | Out-File -FilePath $slug -Encoding utf8

}

function Import-Wikipedia {

    param (
        [string]$url
    )

    #
    # Fetch the content from the URL.
    #
    try {
        #
        # Note: Invoke-WebRequest is used with -UseBasicParsing
        # to avoid a hang that occurs randomly. For more info, see:
        # https://stackoverflow.com/questions/56187543/invoke-webrequest-freezes-hangs
        #
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    } catch {
        Write-Error "Failed to download content from $url. Error: $_"
        return
    }

    #
    # Manually parse the HTML using the StackOverflow solution.
    #
    $parsed = ConvertTo-NormalHTML -HTML $response 

    #
    # Create an array to hold the front matter
    #
    $lines = @()

    #
    # --- (start of front matter)
    #
    $lines += "---"

    #
    # title: "..." (must be enclosed in quotes)
    #
    $title = $parsed.title #$parsed.querySelector("title").innerText
    $title = $title -replace " - Wikipedia$", ""
    $lines += "title: `"$title (Wikipedia)`""    

    #
    # license: CC BY-SA 4.0
    #
    $lines += "license: CC BY-SA 4.0"
    
    #
    # retrieved: yyyy-MM-dd
    #
    $lines += "retrieved: " + (Get-Date -format "yyyy-MM-dd")

    #
    # type: website
    #
    $lines += "type: website"

    #
    # url: /en.wikipedia.org/Wiki/File/
    #
    $lines += "url: /" + ($url -replace "https?://", "" )+ "/"

    #
    # website: "..."
    #
    $lines += "website: `"$url`""

    #
    # wikipedia of: title
    #
    $lines += "wikipedia of: $title"
    
    #
    # tags:
    #
    $lines += "tags:"
    $lines += "  - Wikipedia"

    #
    # --- (end of front matter)
    #
    $lines += "---"

    #
    # Write the content to a file
    #
    $outputPath = "en.wikipedia.org.md"
    $lines | Out-File -FilePath $outputPath -Encoding utf8
}

Export-ModuleMember -Function Import-CommonsPicture
Export-ModuleMember -Function Import-VisibleEarth
Export-ModuleMember -Function Import-Wikipedia