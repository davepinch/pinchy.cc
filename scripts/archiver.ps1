
#
# TODO: start with the home page, and then follow links to archive.
#
$pinchyUrl = "https://pinchy.cc/discourse-on-the-method/4/5/2/"

#
# check() - Checks if the URL has been archived in the Wayback Machine.
#
function check($url) {

    #
    # The curl.exe utility will be used to make the HTTP request to the Wayback Machine API.
    # It is OK to use the version of curl.exe that is installed by default on Windows 10+.
    # Note that PowerShell defines an unrelated alias called "curl" which is not the same
    # as the executable. To avoid conflict, the full name "curl.exe" is used instead of "curl".
    #
    # The API endpoint is https://archive.org/wayback/available?url=<url>

    $response = curl.exe --show-error --silent -X GET https://archive.org/wayback/available?url=$url

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
    return $response | ConvertFrom-Json
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
        $response = check($url)

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
$response = check($pinchyUrl)
if ($response.archived_snapshots.closest) {
    $url = $responseObject.archived_snapshots.closest.url
    Write-Host "Closest archived snapshot URL: $url"
} else {

    Write-Host "No archived snapshots found."
    Write-Host "Attempting to archive the URL..."

    submit($pinchyUrl)
    poll($pinchyUrl)
}