#
# Abort the script if details are not set.
#
if ( ($null -eq $s3access) -or ($null -eq $s3secret) ) {
    Write-Host "S3 details not set. Aborting."
    Write-Host "Please set `$s3access and `$s3secret before running the script."
    Write-Host "You can get your S3 details at https://archive.org/account/s3.php."
    exit
}

# alertSaved() - Beeps to indicate that a URL has been saved.
function alertSaved() {
    [console]::beep(400, 30)
}

function alertAlreadySaved() {
    [console]::beep(100, 50)
}

function alertQueued() {
    [console]::beep(200, 50)
}

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
function wayback($url) {

    # The curl.exe utility will be used to make the HTTP request to the Wayback Machine API.
    # It is safe to use the special version of curl.exe that is installed by default on Windows 10+.
    # Note that PowerShell defines an unrelated alias called "curl" which is not the same
    # as the executable. To avoid conflict, the full name "curl.exe" is used instead of "curl".
    #
    # The API endpoint is https://archive.org/wayback/available?url=<url>

    $requestUrl = "https://archive.org/wayback/available?url=$url"
    $response = curl.exe --show-error --silent -X GET $requestUrl

    if ($null -eq $response) {
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
    # Manually parse the HTML using the StackOverflow solution mentioned above.
    #
    # https://stackoverflow.com/questions/56187543/invoke-webrequest-freezes-hangs
    #
    $NormalHTML = New-Object -Com "HTMLFile"
    $NormalHTML.IHTMLDocument2_write($response.RawContent)

    return $NormalHTML
}

# links() - Returns an array of links from the specified page, excluding
# certain links that are not needed for archiving, e.g., archive.org links.
function links($url) {

    # 
    # Do not generate links for pages outside of https://pinchy.cc.
    #
    if ($url -notmatch "^https://pinchy\.cc") {
        return @()
    }

    $html = FetchHTML($url)
    if ($null -eq $html) {
        Write-Error "Failed to fetch HTML from $url."
        return @()
    }

    $links = @()
    foreach ($link in $html.links) {
        #
        # Check if the link is a valid URL and not an empty string.
        if (($null -eq $link.href) -or ($link.href -eq "")) {
            continue
        }

        # IE returns relative links as "about:page".
        # Skip these for now.
        if ($link.href -and $link.href -notmatch "^http") {
            Write-Host "SKIP: $($link.href)"
            continue
        }

        if ($link.href -match "^https://archive\.org") {
            #
            # Obviously archived links do not need to be archived again.
            #
            Write-Host "SKIP: $($link.href)"
            continue
        }

        if ($link.href -match "^https://www\.bing\.com/maps") {
            #
            # Bing Maps has problems archiving (May 2025, re-check in future).
            #
            Write-Host "SKIP: $($link.href)"
            continue            
        }

        if ($link.href -match "^https://en\.wikipedia\.org") {
            #
            # No need to do extra work for Wikipedia links, they are heavily archived.
            #
            Write-Host "SKIP: $($link.href)"
            continue
        }

        if ($link.href -match "^https://www\.wikidata\.org") {
            # 
            # Same with Wikidata links
            #
            Write-Host "SKIP: $($link.href)"
            continue
        }

        if ($link.href -match "^https://www\.openstreetmap\.org") {
            #
            # Not sure whether OpenStreetMap link archival is useful.
            #
            Write-Host "SKIP: $($link.href)"
            continue
        }
        
        $links += $link.href
    }

    return $links
}

#
# save() - Submits a URL to the Wayback Machine for archiving.
#
function save($url) {
    
    # Docs: https://archive.org/details/spn-2-public-api-page-docs-2023-01-22/page/2/mode/2up
    # Note: when specifying a value, anything other than "1" or "on" will be treated as false.
    #
    # url
    #   The URL to archive.
    #
    # capture_all
    #   Capture a web page with errors (HTTP status=4xx or 5xx). By default SPN2 (Save Page Now)
    #   captures only status=200 URLs.
    #
    # capture_outlinks
    #   Capture web page outlinks automatically. This also applies to PDF, JSON, RSS and MRSS feeds.
    #
    # capture_screenshot
    #   Capture full page screenshot in PNG format. This is also stored in the Wayback Machine
    #   as a different capture.
    #
    # skip_first_archive
    #   Skip checking if a capture is a first if you don’t need this information.
    #   This will make captures run faster.
    #
    # if_not_archived_within
    #   If the URL has not been archived within the specified time period, archive it.
    #   If the page is not archived, job_id in the JSON response will be null.
    $response = curl.exe -X POST `
      -H "Accept: application/json" `
      -H "Authorization: LOW $($s3access):$($s3secret)" `
      "https://web.archive.org/save/" `
      -d "url=$url" `
      -d "capture_all=0" `
      -d "capture_screenshot=0" `
      -d "capture_outlinks=0" `
      -d "if_not_archived_within=30d"

    Write-Host $response
    # {"url":"https://pinchy.cc/proverbs-9-10-kjv/","job_id":"spn2-7505958a4ce9103db9b27172114b3120196230c8"}
    # "Accept: application/json"

    return $response | ConvertFrom-Json
}

#
# Main script execution starts here.
#

$queue = @{}
function dequeue() {
    #
    # Find the first key with a value of false.
    # This is the first URL that has not been archived yet.
    $key = $queue.Keys | Where-Object { $queue[$_] -eq $false } | Select-Object -First 1
    if ($key) {
        $queue[$key] = $true
        return $key
    } else {
        return $null
    }
}
function enqueue($url) {
    if (-not $queue.ContainsKey($url)) {
        $queue[$url] = $false
        return $true
    }
    else {
        return $false
    }
}

function remaining() {
    $remaining = 0
    foreach ($key in $queue.Keys) {
        if ($queue[$key] -eq $false) {
            $remaining += 1
        }
    }
    return $remaining
}

function walk() {

    $url = dequeue
    if ($url) {

        #
        # Get the status of the page from the Wayback Machine API.
        #
        #Write-Host "wayback($url)"
        #$response = wayback($url)

        Write-Host "save($url)"
        $response = save($url)

        if ($null -eq $response.job_id) {
            Write-Host "Already archived: $url"
            alertAlreadySaved
        } else {
            alertSaved
        }
        
        #
        # Get the links from the page to enquee them.
        #
        $links = links($url)
        $links | ForEach-Object {
            $enqueued = enqueue($_)
            if ($enqueued) {
                Write-Host "Enqueued: $_"
                alertQueued
            } else {
                Write-Host "Already in queue: $_"
            }
        }

        return $true
    } else {
        Write-Host "No URLs in queue!"
        return $false
    }

}

$seed = enqueue("https://pinchy.cc/index.html")
while(walk) {

    Write-Host "Waiting for next URL..."
    Write-Host "Total: $($queue.Count)"
    Write-Host "Remaining: $(remaining)"
    Write-Host

    Start-Sleep -Seconds 5
}

Write-Host "All done!"