# if hugo.yaml exists, delete .gitignore and then use git to revert all changes

Remove-Item -Path ".gitignore"
git reset --hard
git clean -fd