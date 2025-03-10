---
title: "Pi in the Pentium: reverse-engineering the constants in its floating-point unit (righto.com)"
author: Ken Shirriff
excerpt: >-
  Intel released the powerful Pentium processor in 1993, establishing a long-running brand of high-performance processors.1 The Pentium includes a floating-point unit that can rapidly compute functions such as sines, cosines, logarithms, and exponentials. But how does the Pentium compute these functions? Earlier Intel chips used binary algorithms called CORDIC, but the Pentium switched to polynomials to approximate these transcendental functions much faster. The polynomials have carefully-optimized coefficients that are stored in a special ROM inside the chip's floating-point unit. Even though the Pentium is a complex chip with 3.1 million transistors, it is possible to see these transistors under a microscope and read out these constants. The first part of this post discusses how the floating point constant ROM is implemented in hardware. The second part explains how the Pentium uses these constants to evaluate sin, log, and other functions.
pi of: Pentium
type: website
url: /www.righto.com/2025/01/pentium-floating-point-ROM.html/
website: "https://www.righto.com/2025/01/pentium-floating-point-ROM.html"
tags:
  - Ken Shirriff's Blog
  - website
---