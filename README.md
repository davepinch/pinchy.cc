# Welcome

This repo contains the content and Hugo source code for my blog at https://pinchy.cc. The blog contains cross-linked notes, snippets, photos, reminders, bookmarks -- anything of interest to me. I use the blog as extended memory.

## Currently working on

I started a script (see collate.ps1) that processes the metadata (YAML front matter) in the markdown files to look for errors and perform automatic cross-referencing. The goal is to minimize redundancy and also begin implementing advanced techniques not easily done with the static site generator. For example, when adding a mountain, the mountain can specify its city and state. The corresponding city and state records need not reference the mountain (it will get added automatically). As another example, it was easy to automatically add a link to a random page on each page. Eventually I expect to simplify the Hugo layout files such that Hugo becomes a simple renderer. I have decided the static site generator should not be implementing any cross-reference logic. Instead I have the script implement the site structure into a data file that can be read by Hugo. It will take some time to update the markdown files.

## Contributing

Send a PR with suggested changes.

## Credits

This blog started with [Jekyll](https://jekyllrb.com/) using the the [Minimal Mistakes Jekyll](https://github.com/mmistakes/minimal-mistakes) theme, which provided great scaffolding to learn Jekyll. Eventually I went "barebones" and removed the theme, but I will forever be greatful to the author.

In November 2023 I migrated to Hugo from Jekyll. Jekyll is an excellent static website generator but I moved to Hugo to take advantage of its Go templating. I will always have a soft spot for Jekyll as the first static website generator I learned. 