---
title: "How to check the current version of Ruby"
linked:
  - _how-to/check-rubygems-version.md
  - _how-to/check-github-pages-dependencies.md
  - _how-to/install-ruby-and-jekyll-on-windows.md
tags:
  - How To
  - Jekyll
  - Ruby
---

Run *ruby -v* in a new terminal window to get the current version.

    ruby -v

You should get a string with the current version and additional build information.

![A screenshot of a PowerShell window showing the output of the ruby -v command](/assets/how-to/check-ruby-version/ruby-version-in-powershell.png)

> Note: You must open a new command prompt or terminal window after running the Ruby installer. This is because the installer updates the PATH to include the Ruby executables; existing terminal windows will still be using the old PATH.

{% include cc0.html %}
