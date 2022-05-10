---
title: "How to include files in Jekyll"
tags:
  - How To
  - Jekyll
---

The `include` tag inserts the contents a file located in the `_includes` folder:

{% raw %}
```liquid
{% include cc0.html %}
```
{% endraw %}

For detailed information, see [Includes](https://jekyllrb.com/docs/includes/) in the official docs. This blog uses the tag to include common markup for specifying a Creative Commons license. For an example, refer to the [source code of this posting](https://github.com/davepinch/davepinch.github.io/blob/master/_posts/2022-05-08-include-html-files-in-jekyll.md).

{% include cc0.html %}