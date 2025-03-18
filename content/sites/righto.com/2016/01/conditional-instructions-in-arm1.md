---
title: "Conditional instructions in the ARM1 processor, reverse engineered (righto.com)"
author: Ken Shirriff
conditional instructions of: ARM1
excerpt: >-
  By carefully examining the layout of the ARM1 processor, it can be reverse engineered. This article describes the interesting circuit used for conditional instructions: this circuit is marked in red on the die photo below. Unlike most processors, the ARM executes every instruction conditionally. Each instruction specifies a condition and is only executed if the condition is satisfied. For every instruction, the condition circuit reads the condition from the instruction register (blue), evaluates the condition flags (purple), and informs the control logic (yellow) if the instruction should be executed or skipped.
type: website
url: /www.righto.com/2016/01/conditional-instructions-in-arm1.html/
website: "https://www.righto.com/2016/01/conditional-instructions-in-arm1.html"
tags:
  - Ken Shirriff's blog
  - website
---