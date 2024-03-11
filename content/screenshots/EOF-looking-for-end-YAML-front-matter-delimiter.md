---
title: "EOF looking for end YAML front matter delimiter"
date: 2024-03-10
excerpt: >-
  Error: error building site: assemble: "/home/runner/work/pinchy.cc/pinchy.cc/content/topics/computers/programming-languages/altair-basic/archive-january-1975-popular-electronics.md:1:1": EOF looking for end YAML front matter delimiter
related: 
  - "197501 Popular Electronics : Ziff-Davis Publishing Company (archive.org)"
type: picture
picture: /screenshots/EOF-looking-for-end-YAML-front-matter-delimiter/EOF-looking-for-end-YAML-front-matter-delimiter.png"
thumbnail: /screenshots/EOF-looking-for-end-YAML-front-matter-delimiter/EOF-looking-for-end-YAML-front-matter-delimiter.png"
when: 2024-03-10
tags:
  - Hugo
  - YAML
  - front matter
  - error
  - screenshot
  - GitHub Pages
---

https://github.com/davepinch/pinchy.cc/commit/3fa06424e860c13261688ccedb467fd2b196e72b

I accidentally used === as a front matter delimiter. Fixed by changing the === to ---.