# wayback() - Gets the status of a page from the Wayback Machine.
#
# The API returns a JSON response with information about the closest archived snapshot.
# The response will look something like this:
#
# {
#    "archived_snapshots": {
#        "closest": {
#            "available": true,
#            "url": "http://web.archive.org/web/20130919044612/http://example.com/",
#            "timestamp": "20130919044612",
#            "status": "200"
#        }
#    }
# }
#
# The JSON response is parsed into a PowerShell object using ConvertFrom-Json.
function wayback($url) {

    # The curl.exe utility will be used to make the HTTP request to the Wayback Machine API.
    # It is OK to use the version of curl.exe that is installed by default on Windows 10+.
    # Note that PowerShell defines an unrelated alias called "curl" which is not the same
    # as the executable. To avoid conflict, the full name "curl.exe" is used instead of "curl".
    #
    # The API endpoint is https://archive.org/wayback/available?url=<url>

    $response = curl.exe --show-error --silent -X GET https://archive.org/wayback/available?url=$url

    if ($null -eq $null) {
        Write-Error "Failed to fetch data from Wayback Machine API."
        return $null
    }

    return $response | ConvertFrom-Json
}

function FetchHTML([string]$url) {

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
    # https://stackoverflow.com/questions/56187543/invoke-webrequest-freezes-hangs
    #
    $NormalHTML = New-Object -Com "HTMLFile"
    $NormalHTML.IHTMLDocument2_write($response.RawContent)

    return $NormalHTML
}

function fetchLinks($url) {

    $html = FetchHTML($url)
    if ($null -eq $html) {
        Write-Error "Failed to fetch HTML from $url."
        return @()
    }

    $links = @()
    foreach ($link in $html.links) {
        #
        # Check if the link is a valid URL and not an empty string.
        # Also, check if the link is not "about:/", which is a placeholder.
        # This is a workaround for the issue where IE prefixes about: in front
        # of a relative URL.
        #
        if ($link.href -and $link.href -ne "about:/") {
            $links += $link.href
        }
    }

    return $links
}

#
# poll() - Polls the Wayback Machine API to check if the URL has been archived.
#
function poll($url) {

    $maxAttempts = 6
    $delaySeconds = 10
    $attempt = 0
    $archived = $false

    while (-not $archived -and $attempt -lt $maxAttempts) {
        Start-Sleep -Seconds $delaySeconds
        $attempt++

        Write-Host "Checking archive status (attempt $attempt)..."
        $response = wayback($url)

        if ($response.archived_snapshots.closest) {
            $snapshotUrl = $response.archived_snapshots.closest.url
            Write-Host "Page archived! Snapshot URL: $snapshotUrl"
            $archived = $true
        }
    }    
}

#
# submit() - Submits a URL to the Wayback Machine for archiving.
#
function submit($url) {
    Write-Host "Submitting URL for archiving..."
    curl.exe --show-error --silent -X GET https://web.archive.org/save/$url
}

#
# Main script execution starts here.
#

#
# TODO: start with the home page, and then follow links to archive.
#
$pinchyUrl = "https://pinchy.cc/"

#
# Get the links from the page to enquee them.
#
$links = fetchLinks($pinchyUrl)
$links | ForEach-Object {
    Write-Host "Found link: $_"
}

#$response = check($pinchyUrl)
#if ($response.archived_snapshots.closest) {
#    $url = $responseObject.archived_snapshots.closest.url
#    Write-Host "Closest archived snapshot URL: $url"
#} else {
#
#    Write-Host "No archived snapshots found."
#    Write-Host "Attempting to archive the URL..."
#
#    submit($pinchyUrl)
#    poll($pinchyUrl)
#}