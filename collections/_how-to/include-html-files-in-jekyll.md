---
title: "How to include files in Jekyll"
tags:
  - How To
  - Jekyll
---

The `include` tag inserts the contents a file located in the `_includes` folder. You must specify the file extension.

{% raw %}
```liquid
{% include cc0.html %}
```
{% endraw %}

For detailed information, see [Includes](https://jekyllrb.com/docs/includes/) in the Jekyll docs. For an example, refer to the [source code of this posting](https://github.com/davepinch/pinchy.cc/blob/master/collections/_how-to/include-html-files-in-jekyll.md), which uses the include tag to show the Creative Commons license information.

{% include cc0.html %}