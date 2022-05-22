---
title: “Moved to pinchy.cc”
author_profile: true
tags:
  - GitHub Pages
  - Meta
---

I decided to move this site from davepinch.com to pinchy.cc while switching to a new GitHub repro.

Requirements:

* Keep all change history
* Serve content on pinchy.cc

Non-Requirements:

* Search engine optimization, redirects, etc. (the site is too new for me to waste time)

 I was a bit worried due to the coordination between duplicating the repro, re-creating GitHub Pages, and configuring the new domain - but it was made easier with the following docs:

https://gist.github.com/niksumeiko/8972566

## Clean

First, I pushed local changes and cleared about any unwanted pending changes.


## Create new repro
I signed into my GitHub account and created an empty repo *pinchy.cc*. I did not initialize the repo with a license or readme because the contents will be migrated later.



git remote add new-origin https://github.com/davepinch/pinchy.cc.git
git push --all new-origin
git push --tags new-origin
git remote -v
git remote rm origin
git remote rename new-origin origin

PS C:\Users\David\Documents\pinchy.cc> git config user.email "davepinch@gmail.com"
PS C:\Users\David\Documents\pinchy.cc> git config user.name "Dave Pinch"
