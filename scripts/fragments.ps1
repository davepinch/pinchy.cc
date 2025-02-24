#
# fragments
#
# This script takes pictures of the website using the headless
# browser and constructs a video using the images.
#

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

function NavigateToNext($html) {
    $anchorTags = $html.getElementsByTagName("a")
    foreach ($tag in $anchorTags) {
        if ($tag.className -eq "cc-next") {
            $href = $tag.href

            #
            # For some reason, IE prefixes about: in front of a relative URL.
            # Not sure what happens with absolute URLs. Either way, remove
            # the about: prefix.
            #
            if ($href.StartsWith("about:")) {
                $href = $href.Substring(6)
            }

            if ($href.StartsWith("/")) {
                $href = "https://pinchy.cc$href"
            }

            return $href
        }
    }
}

function TakeScreenshot {
    param (
        [string]$WebsiteURL,
        [string]$OutputFile
    )

    #
    # TODO: stop using hard-coded path. Support Chrome too.
    #
    $BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

    $arguments = `
        "--headless " + `
        "--screenshot=$OutputFile " + `
        "--disable-gpu " + `
        "--hide-scrollbars " + `
        "--window-size=1280,720 " + `
        $WebsiteURL

    # Take screenshot using Edge (or Chrome if changed)
    # Credit: Copilot was instrumental in finding this approach to getting a screenshot.
    Start-Process -FilePath $BrowserPath -ArgumentList $arguments -NoNewWindow -Wait
}

$index = 0
$website = "https://pinchy.cc/hello-world/"

do {

    TakeScreenshot -WebsiteURL $website -OutputFile "$PSScriptRoot\screenshot-$index.png"

    $thisContent = FetchHTML $website
    $website = NavigateToNext -html $thisContent
    $index++

} while ($index -lt 10)

#
# From ChatGPT:
# -framerate 1/10: This sets the frame rate to 1 frame every 10 seconds, so each image stays for 10 seconds.
# -i "image%d.png": Specifies the input files. The %d indicates a sequence of files named like image1.png, image2.png, etc.
# -c:v libx264: Specifies the video codec (H.264).
# -r 30: Sets the output video frame rate to 30 FPS (standard for smooth video).
# -pix_fmt yuv420p: Ensures compatibility with most video players.
# output_video.mp4: The name of the output video file.

ffmpeg -framerate 1/3 -i "screenshot-%d.png" -c:v libx264 -r 30 -pix_fmt yuv420p output_video.mp4
