---
title: "How to check the current version of Ruby"
tags:
  - How To
  - Jekyll
  - Ruby
---

Run *ruby -v* in a new terminal window to get the current version.

    ruby -v

You should get a string with the current version and additional build information.

![A screenshot of a PowerShell window showing the output of the ruby -v command](/assets/images/2022/2022-05-07-check-ruby-version/ruby-version-in-powershell.png)

> Note: You must open a new command prompt or terminal window after running the Ruby installer. This is because the installer updates the PATH to include the Ruby executables; existing terminal windows will still be using the old PATH.

{% include cc0.html %}

## See Also 

* [How to check the current version of RubyGems]({% post_url 2022-05-07-check-rubygems-version %})
* [How to check the version of Jekyll and Ruby used by GitHub Pages]({% post_url 2022-05-07-check-github-pages-dependencies %})
* [How to install Ruby and Jekyll on Windows]({% post_url 2022-05-07-install-ruby-and-jekyll-on-windows %})
