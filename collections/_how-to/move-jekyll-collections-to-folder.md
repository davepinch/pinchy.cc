---
title: "How to move Jekyll collections to a custom directory"
tags:
  - Jekyll
---
If your Jekyll project contains multiple custom directories, you can move them to a single parent directory to tidy up your root directory.

1. Create a directory to hold the custom collections, e.g., *collections*. The name cannot start with an underscore (_) character.

2. Specify the name of the directory in _config.yml with the *collections_dir* setting.

3. Move the _posts and the _drafts directories to the new directory.

4. Move your existing custom folders to the new directory.

## Jekyll Docs

* [Collections](https://jekyllrb.com/docs/collections/)
* [Configuration](https://jekyllrb.com/docs/configuration/front-matter-defaults/)
