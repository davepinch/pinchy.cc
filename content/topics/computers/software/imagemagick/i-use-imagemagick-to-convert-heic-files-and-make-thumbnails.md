---
title: "I use ImageMagick to convert HEIC files and make thumbnails."
next: ImageMagick (imagemagick.org)
---

* To convert from a HEIC to a JPG, I use the following command line:

    magick source.heic target.jpg

* To make a thumbnail, I use the following:

    magick filename.jpg -resize 300x filename.thumbnail.jpg

Note that 300x lets me set the horizontal size without specifying the vertical size. I also append ".thumbnail.jpg" to the filename. This ensures the thumbnails are sorted after the main file when viewed in a file listing.

ImageMagick has many, many other options for conversion and thumbnail creation.