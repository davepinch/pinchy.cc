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

    $requestUrl = "https://archive.org/wayback/available?url=$url"
    Write-Host "Requesting: $requestUrl"
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
    # Manually parse the HTML using the StackOverflow solution.
    #
    # https://stackoverflow.com/questions/56187543/invoke-webrequest-freezes-hangs
    #
    $NormalHTML = New-Object -Com "HTMLFile"
    $NormalHTML.IHTMLDocument2_write($response.RawContent)

    return $NormalHTML
}

function links($url) {

    # 
    # Do not generate links if the page is not in https://pinchy.cc.
    #
    if ($url -notmatch "^https://pinchy\.cc") {
        Write-Host "NOLINKS: $url"
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

        $links += $link.href
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
        Write-Host "wayback($url)"
        $response = wayback($url)

        if ($response.archived_snapshots.closest) {
            Write-Host "Already archived: $url"
            [console]::beep(100, 500)
        } else {
            #Write-Host "No archived snapshots found."
            Write-Host "Attempting to archive the URL..."
            #submit($url)
            #poll($url)
        }

        #
        # Get the links from the page to enquee them.
        #
        $links = links($url)
        $links | ForEach-Object {
            $enqueued = enqueue($_)
            if ($enqueued) {
                Write-Host "Enqueued: $_"
            } else {
                [console]::beep(100, 100)
                Write-Host "Already in queue: $_"
            }
        }

        return $true
    } else {
        Write-Host "No URLs in queue."
        return $false
    }

}

enqueue("https://pinchy.cc/index.html")
while(walk) {
    # Do nothing, just wait for the next URL to be processed.
    Write-Host "Waiting for next URL..."
    Write-Host "Queue: $($queue.Count)"
    Write-Host "Remaining: $(remaining)"
    Write-Host

    Start-Sleep -Seconds 5
}
