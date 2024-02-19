---
title: "The Simulation scratchpad"
tags:
  - The Simulation
  - scratchpad
---
If the simulator is running on a von neumann architecture, then code and data are stored in the same address space of simulator memory. This doesn't imply any ability to access code or data outside of the interface enforced by the simulator. In fact, in modern operating systems a userland program cannot access the entire memory space of the computer. Doing so will cause an access violation and typically halt the program. If the simulator is running on a von neumann architecture, then all we can say is that the code and data coexist in a unified address space.