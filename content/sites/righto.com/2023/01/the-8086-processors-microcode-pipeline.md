---
title: "The 8086 processor's microcode pipeline from die analysis (righto.com)"
author: Ken Shirriff
excerpt: >-
  Intel introduced the 8086 microprocessor in 1978, and its influence still remains through the popular x86 architecture. The 8086 was a fairly complex microprocessor for its time, implementing instructions in microcode with pipelining to improve performance. This blog post explains the microcode operations for a particular instruction, "ADD immediate". As the 8086 documentation will tell you, this instruction takes four clock cycles to execute. But looking internally shows seven clock cycles of activity. How does the 8086 fit seven cycles of computation into four cycles? As I will show, the trick is pipelining.
microcode pipeline of: Intel 8086
type: website
url: /www.righto.com/2023/01/the-8086-processors-microcode-pipeline.html/
website: "https://www.righto.com/2023/01/the-8086-processors-microcode-pipeline.html"
tags:
  - Ken Shirriff's blog
  - website
---