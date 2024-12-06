
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
    $localUrl = $localUrl -replace "^/wiki/File:", "/wiki/"
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

function Import-Wikipedia {

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
    $title = $content.ParsedHtml.querySelector("title").innerText
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
Export-ModuleMember -Function Import-Wikipedia