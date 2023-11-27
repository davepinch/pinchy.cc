param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
    [string]$HEICFilePath
)

# Get the folder path of the HEIC file
$folderPath = Split-Path -Path $HEICFilePath -Parent

# Set the output JPEG file path
$JPEGFilePath = Join-Path -Path $folderPath -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($HEICFilePath)).jpg"

# Set the output thumbnail path
$ThumbnailPath = Join-Path -Path $folderPath -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($HEICFilePath))-thumbnail.jpg"

# Convert HEIC to JPEG using Magick
magick convert $HEICFilePath $JPEGFilePath

# Create a thumbnail of the HEIC using magick
magick convert $HEICFilePath -resize 300x $ThumbnailPath