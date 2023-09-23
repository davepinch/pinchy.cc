# if hugo.yaml exists, delete .gitignore and then use git to revert all changes

if (test-path -Path "hugo.yaml") {
  Remove-Item -Path ".gitignore"
  git reset --hard
  git clean -fd
}
