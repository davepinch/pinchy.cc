---
title: "Conditions in the Intel 8087 floating-point chip's microcode (righto.com)"
author: Ken Shirriff
conditions of: Intel 8087
excerpt: >-
  In the 1980s, if you wanted your computer to do floating-point calculations faster, you could buy the Intel 8087 floating-point coprocessor chip. Plugging it into your IBM PC would make operations up to 100 times faster, a big boost for spreadsheets and other number-crunching applications. The 8087 uses complicated algorithms to compute trigonometric, logarithmic, and exponential functions. These algorithms are implemented inside the chip in microcode. I'm part of a group that is reverse-engineering this microcode. In this post, I examine the 49 types of conditional tests that the 8087's microcode uses inside its algorithms. Some conditions are simple, such as checking if a number is zero or negative, while others are specialized, such as determining what direction to round a number.
retrieved: 2026-03-14
type: website
url: /www.righto.com/2025/12/8087-microcode-conditions.html/
website: "https://www.righto.com/2025/12/8087-microcode-conditions.html"
tags:
  - Ken Shirriff's Blog
  - website
---