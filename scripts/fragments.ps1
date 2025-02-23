#
# fragments
#
# This script takes pictures of the website using the headless
# browser and constructs a video using the images.
#

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

TakeScreenshot -WebsiteURL "https://pinchy.cc/hello-world/" -OutputFile "$PSScriptRoot\screenshot.png"

