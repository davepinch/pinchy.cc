---
title: "How to save a draft in Jekyll"
tags:
  - How To
  - Jekyll
---

## Move the post to the _drafts folder

* Posts in the *_drafts* folder are not published to the site.
* The file doesn't need a date prefix.
* You can [preview drafts](https://jekyllrb.com/docs/posts/#drafts) by running jekyll serve or jekyll build with the --drafts switch. They will be ordered with posts based on last modification date.

## Set published to false

Alternately, you can set *published* to false in the [front matter](https://jekyllrb.com/docs/front-matter/) of the post. This approach lets you keep your draft copy with other posts -- however, it is technically not a draft and will not get published if you run Jekyll with the --drafts switch.

## Reference

* [Front Matter - Jekyll Docs](https://jekyllrb.com/docs/front-matter/)
* http://seanlaw.github.io/2015/03/14/jekyll-drafts/


