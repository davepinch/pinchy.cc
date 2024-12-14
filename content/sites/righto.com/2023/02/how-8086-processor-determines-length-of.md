---
title: "How the 8086 processor determines the length of an instruction (righto.com)"
author: Ken Shirriff
excerpt: >-
  The Intel 8086 processor (1978) has a complicated instruction set with instructions ranging from one to six bytes long. This raises the question of how the processor knows the length of an instruction.1 The answer is that the 8086 uses an interesting combination of lookup ROMs and microcode to determine how many bytes to use for an instruction. In brief, the ROMs perform enough decoding to figure out if it needs one byte or two. After that, the microcode simply consumes instruction bytes as it needs them. Thus, nothing in the chip explicitly "knows" the length of an instruction. This blog post describes this process in more detail.
instruction length decoding of: Intel 8086
type: website
url: /www.righto.com/2023/02/how-8086-processor-determines-length-of.html/
website: "https://www.righto.com/2023/02/how-8086-processor-determines-length-of.html"
tags:
  - Ken Shirriff's blog
  - website
---