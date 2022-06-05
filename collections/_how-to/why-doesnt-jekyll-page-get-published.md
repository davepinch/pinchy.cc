---
title: "Why doesn't a Jekyll post get published?"
tags:
  - How To
  - Jekyll
---
If a page isn't getting published, check the following:

* A post with a future date prefix won't get published unless the future variable is true or the site is built with the --future parameter.
* A page won't get published if published is set to false.
* A page in the _drafts folder won't get published unless the unpublished variable is true or the site is built with the --unpublished parameter.
* Files or directories that begin with a ., _, #, or ~ will not be processed unless they are specified in the config file with the include variable.
