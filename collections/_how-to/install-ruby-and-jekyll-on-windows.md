---
title: "How to install Ruby and Jekyll on Windows 10"
tags:
  - GitHub Pages
  - How To
  - Jekyll
  - Ruby
---

**[TL;DR](https://en.wiktionary.org/wiki/tl;dr)** The easiest option is to download and install Ruby+DevKit at [https://rubyinstaller.org](https://rubyinstaller.org). You can then install Jekyll with the *gem install jekyll* command as described at [Jekyll on Windows](https://jekyllrb.com/docs/installation/windows/).

If you are building a Jekyll site to host on GitHub Pages, you may want to install the specific versions used by that service. As of May 2022, GitHub Pages has a dependency on an older version of Jekyll that is not fully compatible with the latest version of Ruby. To avoid any issues, [get the current versions of Jekyll and Ruby used by GitHub Pages]({% link _how-to/check-github-pages-dependencies.md %}) and make a note of those version numbers so you can get the matching installers.

## Install Wizard

**[TL;DR](https://en.wiktionary.org/wiki/tl;dr)** Install Ruby and MSYS32 with default options. Ensure Ruby executables are in your PATH. 

### Ruby Installer Step 1: License agreement
![Screenshot of the license agreement step of the Ruby installer](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ruby-installer-step-1-license.png)

### Ruby Installer Step 2: Installation destination and options

Be sure to keep the option to add Ruby executables to your PATH. This will allow you to run Ruby from any terminal window.

![Screenshot of the Installation Destination and Optional Tasks step of the Ruby installer](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ruby-installer-step-2-destination.png)

### Ruby Installer Step 3: Components

![Screenshot of the Select Components step of the Ruby installer](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ruby-installer-step-3-components.png)

### Ruby Installer Step 4: Installing...

Let it run for a while...

![](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ruby-installer-step-4-installing.png)

### Ruby Installer Step 5: Completing

Once files are installed, you will be prompted to install MSYS32 and the development toolchain. Keep the option selected as you will need it to build certain gems.

![Screenshot of the Completing the Ruby Setup Wizard step of the Ruby installer](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ruby-installer-step-5-completing.png)

### MSYS32 Installer

A console window will appear and present options for installing or updating MSYS32 and the development toolchain. 

![Screenshot of a terminal window showing the startup screen of the ridk installer. The user is prompted to select from three options. Pressing Enter selects the recommended options of 1 and 3.](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ridk-install-1.png)

Press Enter to select the recommended options (1, 3). Let the script run for a while. Don't worry about yellow warnings.

![](/assets/images/2022/2022-05-07-install-ruby-and-jekyll-on-windows/ridk-install-3.png)

In a few moments you will be returned back to the prompt. Press Enter to exit the script and close the window. **Congrats - you have installed Ruby!**

{% include cc0.html %}

## See Also

* [How to install Jekyll](%{ link _how-to/install-jekyll.md %}) (high-level instructions)
* [How to check the version of Jekyll and Ruby used by GitHub Pages]({% link _how-to/check-github-pages-dependencies.md %})
* [How to check the current version of Ruby]({% link _how-to/check-ruby-version.md %})

