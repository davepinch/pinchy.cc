function Get-EmojiOpenFolder() {
    return [System.Char]::ConvertFromUtf32(0x1F4C2)
}

Write-Host "hello world"

Get-ChildItem | ForEach-Object {
    if ($_.PSIsContainer) {
        Write-Host "$(Get-EmojiOpenFolder) $_"
    } else {
        Write-Host "  $_"
    }
}