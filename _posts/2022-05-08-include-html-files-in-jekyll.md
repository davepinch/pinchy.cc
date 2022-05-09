---
title: "How to include files in Jekyll"
categories:
  - Guides
tags:
  - Jekyll
---

The `include` tag inserts the contents a file located in the `_includes` folder:

{% raw %}
```liquid
{% include cc0.html %}
```
{% endraw %}

For detailed information, see [Includes](https://jekyllrb.com/docs/includes/) in the official docs. This blog uses the tag to include common markup for specifying a Creative Commons license. 

{% include cc0.html %}