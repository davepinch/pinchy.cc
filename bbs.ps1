function Get-EmojiFile() {
    return [System.Char]::ConvertFromUtf32(0x1F4C4)
}

function Get-EmojiOpenFolder() {
    return [System.Char]::ConvertFromUtf32(0x1F4C2)
}

function Get-Icon($item) {
    if ($_.PSIsContainer) {
        return Get-EmojiOpenFolder
    } else {
        return Get-EmojiFile
    }
}

#
# Functions beginning with an underscore (_) are prototypes that
# are under development and will be renamed to conventional form.
#

function _DIR($criteria) {
    Get-ChildItem | ForEach-Object {
        if ($_.Name -like "$criteria*") {
            Write-Host "$(Get-Icon($_)) $_"
        }
    }
}

function _EXEC($command) {
    _DIR $command
}

function _READ {
    return Read-Host ":"
}

Write-Host "hello world"
_DIR

do {
    $userInput = _READ
    if ($userInput -eq "exit") {
        break
    }
    _EXEC $userInput
} while ($true)