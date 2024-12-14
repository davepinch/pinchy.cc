---
title: "Reverse engineering the Intel 386 processor's register cell (righto.com)"
author: Ken Shirriff
excerpt: >-
  The groundbreaking Intel 386 processor (1985) was the first 32-bit processor in the x86 line. It has numerous internal registers: general-purpose registers, index registers, segment selectors, and more specialized registers. In this blog post, I look at the silicon die of the 386 and explain how some of these registers are implemented at the transistor level. The registers that I examined are implemented as static RAM, with each bit stored in a common 8-transistor circuit, known as "8T". Studying this circuit shows the interesting layout techniques that Intel used to squeeze two storage cells together to minimize the space they require.
register cell of: Intel 386
type: website
url: /www.righto.com/2023/11/reverse-engineering-intel-386.html/
website: "https://www.righto.com/2023/11/reverse-engineering-intel-386.html"
tags:
  - Ken Shirriff's blog
  - website
---