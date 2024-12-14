---
title: "How the 8086 processor's microcode engine works (righto.com)"
author: Ken Shirriff
excerpt: >-
  The 8086 microprocessor was a groundbreaking processor introduced by Intel in 1978. It led to the x86 architecture that still dominates desktop and server computing. The 8086 chip uses microcode internally to implement its instruction set. I've been reverse-engineering the 8086 from die photos and this blog post discusses how the chip's microcode engine operated. I'm not going to discuss the contents of the microcode1 or how the microcode controls the rest of the processor here. Instead, I'll look at how the 8086 decides what microcode to run, steps through the microcode, handles jumps and calls inside the microcode, and physically stores the microcode. It was a challenge to fit the microcode onto the chip with 1978 technology, so Intel used many optimization techniques to reduce the size of the microcode.
microcode engine of: Intel 8086
type: website
url: /www.righto.com/2022/11/how-8086-processors-microcode-engine.html/
website: "https://www.righto.com/2022/11/how-8086-processors-microcode-engine.html"
tags:
  - Ken Shirriff's blog
  - website
---