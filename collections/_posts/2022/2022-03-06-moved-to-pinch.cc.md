---
title: “Moved to pinchy.cc”
date: 2022-03-06
tags:
  - GitHub
---

The following instructions explain how to move a Git repro:

https://gist.github.com/niksumeiko/8972566

Background: This blog was originally on [davepinch.com](https://davepinch.com) but I decided to move to pinchy.cc with a new GitHub repo. I wanted to keep all change history. I was worried about the complexity of duplicating the repro, recreating GitHub pages, configuring the domain, etc. However, the repo move was made easy with the above instructions. Here are the commands I used:

  git remote add new-origin https://github.com/davepinch/pinchy.cc.git
  git push --all new-origin
  git push --tags new-origin
  git remote -v
  git remote rm origin
  git remote rename new-origin origin