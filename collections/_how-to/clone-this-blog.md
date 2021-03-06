---
title: How to clone this blog with Git
tags:
  - How To
  - Jekyll
  - This
---

This blog is open source and all content is stored in the [pinchy.cc](https://github.com/davepinch/pinchy.cc) repo on GitHub. Here is the git command to clone the repo:

    git clone https://github.com/davepinch/pinchy.cc.git

To run locally, you need to [install Jekyll and Ruby]({% link _how-to/install-jekyll.md %}) on your computer. Once installed, the following command will build the website and start a local web server:

    bundle exec jekyll serve

Then open your browser to [http://localhost:4000/](http://localhost:4000/).

This blog is under heavily development and will be refactored constantly.
{: .notice--warning }
