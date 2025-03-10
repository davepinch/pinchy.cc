---
title: "Analyzing the vintage 8008 processor from die photos: its unusual counters (righto.com)"
author: Ken Shirriff
counters of: Intel 8008
excerpt: >-
  The revolutionary Intel 8008 microprocessor is 45 years old today (March 13, 2017), so I figured it's time for a blog post on reverse-engineering its internal circuits. One of the interesting things about old computers is how they implemented things in unexpected ways, and the 8008 is no exception. Compared to modern architectures, one unusual feature of the 8008 is it had an on-chip stack for subroutine calls, rather than storing the stack in RAM. And instead of using normal binary counters for the stack, the 8008 saved a few gates by using shift-register counters that generated pseudo-random values. In this article, I reverse-engineer these circuits from die photos and explain how they work.
type: website
url: /www.righto.com/2017/03/analyzing-vintage-8008-processor-from.html/
website: "https://www.righto.com/2017/03/analyzing-vintage-8008-processor-from.html"
tags:
  - Ken Shirriff's Blog
  - website
---