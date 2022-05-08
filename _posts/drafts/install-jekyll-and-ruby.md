---
title: "How to install Jekyll and Ruby on Windows 10"
categories:
  - Guides
tags:
  - GitHub Pages
  - Jekyll
  - Ruby
---
I am new to Ruby and want the most frictionless experience while being able to work in Visual Studio Code. I want sane defaults and the ability to expand into Ruby programming when I felt like it. I am willing to use an older version as long as it does not limit me.

GitHub Pages has a dependency on an older version of Jekyll that is not fully compatible with the latest version of Ruby. This can cause issues for people using newer versions on their computers.

 This guide describes how to install the latest versions compatible with GitHub pages.


## Prerequisites

* [Get the current versions of Jekyll and Ruby used by GitHub Pages](./2022-05-07-check-github-pages-dependencies.md).


##

* https://powers-hell.com/2021/07/25/build-a-jekyll-development-environment-with-vs-code-remote-containers/
* https://code.visualstudio.com/docs/remote/create-dev-container

* https://purple.telstra.com.au/blog/opensource-blogging-with-jekyll-github-vscode-part-1


## Download Ruby+DevKit 2.x for Windows

**[TL;DR](https://en.wiktionary.org/wiki/tl;dr)** Download Ruby+DevKit 2.x at https://rubyinstaller.org

### Background

Ruby is a programming language used by Jekyll to convert your content into HTML and CSS. You don't need to know Ruby programming to get started, but you do need to install Ruby so you can build and test your website locally on your Windows computer.

> **IMPORTANT:** As of May 2022, GitHub Pages has a dependency on Jekyll 3.9.2, which is not fully compatible with Ruby 3.x. Therefore these instructions direct you to install the 2.x version of Ruby used by GitHub Pages. You can try installing later versions of Ruby but you might encounter issues not described in this guide. See https://github.com/github/docs/issues/17504

1. Go to https://rubyinstaller.org/downloads/ 
2. Review the installer recommendations and other notes.
3. Install the exact version specified at []
3. Download the latest 2.x x64 version of the Ruby+DevKit installer. As of May 2022, the latest compatible version is Ruby+DevKit 2.7.6-1 (x64).

## Install Ruby 2.x on Windows

**[TL;DR](https://en.wiktionary.org/wiki/tl;dr)** Install Ruby and MSYS32 with default options. Ensure Ruby executables are in your PATH.

### Ruby Installer Step 1: Accept license agreement
![Screenshot of license agreement step of the Ruby installer](/assets/guides/ruby-installer/installer-page-1.png)

### Ruby Installer Step 2: Specify folder and installation options

Be sure to keep the option to add Ruby executables to your PATH. This will allow you to run Ruby from other folders such as a Visual Studio Code terminal window.

![Screenshot of the Installation Destination and Optional Tasks step of the Ruby installer](/assets/guides/ruby-installer/installer-page-2.png)

### Ruby Installer Step 3: Select all components to install

![Screenshot of the Select Components step of the Ruby installer](/assets/guides/ruby-installer/installer-page-3.png)

### Ruby Installer Step 4: Install files...

Let it run for a while...

![](/assets/guides/ruby-installer/installer-page-4.png)

### Ruby Installer Step 5: 

Once files are installed, you will be prompted to install MSYS32 and the development toolchain. Keep the option selected as you will need it to build certain gems.

![Screenshot of the Completing the Ruby Setup Wizard step of the Ruby installer](/assets/guides/ruby-installer/installer-step-5.png)

### MSYS32 Installer

A console window will appear and present options for installing or updating MSYS32 and the development toolchain. 

![](/assets/guides/ruby-installer/installer-step-6-ridk-install.png)

Press Enter to select the recommended options (1, 3). Let the script run for a while. Don't worry about yellow warnings.

![](/assets/guides/ruby-installer/installer-step-7-ridk-script-finished.png)

Finally you will be returned back to the prompt. Press Enter to exit the script and close the window. **Congrats - you have installed Ruby!**

## Confirm Ruby Installation

**[TL;DR](https://en.wiktionary.org/wiki/tl;dr)** Run *ruby -v* in a new terminal window to confirm installation.

Open a command prompt (CMD or PowerShell) and type the following command:

    ruby -v

You should see ruby 2.x and some additional build information.

![A screenshot of a PowerShell window showing the output of the ruby -v command](/assets/guides/ruby-installer/ruby-version-powershell.png)

> Note: You must open a new command prompt or terminal window after running the installer. You may need to restart Visual Studio Code. This is because the installer updates the PATH to include the Ruby executables; existing terminal windows will still be using the old PATH.

If you get a 'not recognized' error even after opening a new terminal window, restart Visual Studio Code (if applicable). Otherwise you probably need to add the Ruby *bin* folder to your PATH. The bin folder is most likely C:\Ruby27-x64\bin if you selected the default installer options. You can add this folder to the PATH environment variable in Windows Settings or your custom scripts. 

## Check current version of RubyGems

[RubyGems](https://en.wikipedia.org/wiki/RubyGems) is a package management system for Ruby. It makes it easy to download and install *gems*, which are packages of code that can be used by your scripts and other gems. RubyGems is already installed by the Ruby Installer. Run the following command to confirm installation and check the verion:

    gem -v

You should see "3.1.6". To update:

    gem update --system

For more commands, see https://guides.rubygems.org/command-reference/. 

## Jekyll and Bundler

Github uses Jekyll 3.9.2, which is not the latest major version of Jekyll. This guide assumes you are installing 3.9.2 to ensure compatibility with Github.

    gem install jekyll bundler

