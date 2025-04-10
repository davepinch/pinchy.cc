
#
# PowerShell defines an alias called "curl" which is not the same as
# the cURL command-line tool that is  installed by default on Windows 10+.
# To avoid conflict, the full name "curl.exe" is used instead of "curl".
#
$response = curl.exe --show-error --silent -X GET https://archive.org/wayback/available?url=https://pinchy.cc/

#
# Convert the JSON response to a PowerShell object
#
$responseObject = $response | ConvertFrom-Json

if ($responseObject.archived_snapshots.closest) {
    $url = $responseObject.archived_snapshots.closest.url
    Write-Host "Closest archived snapshot URL: $url"
} else {
    Write-Host "No archived snapshots found."
}
