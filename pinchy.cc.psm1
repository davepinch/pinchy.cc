function Import-Wikipedia {

    param (
        [string]$url
    )

    #
    # Create an array to hold the front matter
    #
    $lines = @()

    #
    # Fetch the content from the URL.
    #
    try {
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing
    } catch {
        Write-Error "Failed to download content from $url. Error: $_"
        return
    }

    #
    # --- (start of front matter)
    #
    $lines += "---"

    #
    # title: "..." (must be enclosed in quotes)
    #
    $lines += "title: `"$($content.ParsedHtml.title)`""

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

Export-ModuleMember -Function Import-Wikipedia