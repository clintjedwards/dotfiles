### Backup NAS to google cloud

> Tar and compress what we can

`tar -I pigz -cf nasafe.tar.gz documents music software weow`

> Encrypt the tar ball

`gpg -c nasafe.tar.gz`

> Upload the tarball to GCP

`gsutil cp nasafe.tar.gz.gpg gs://production-161206-cold-backups`

### [Setting up autorandr](https://github.com/phillipberndt/autorandr)

> First you have to get the current state of displays.

`xrandr --current`

> Then you set up the display and connections how you want them

`xrandr --output eDP1 --off && xrandr --output HDMI --primary --auto`

> Then for each set up you want, save them with autorandr and autorandr will auto detect when it is in a state that you've saved and run the correct command.

`autorandr --save <name>`

> manually reload with

`autorandr --change`

### Symlink syntax (because I always forget)

`ln -s ~/Documents/dotfiles/vscode/settings.json settings.json`

### Git stuff

> Squash and rebase a branch against main

`git rebase origin/master -i`

> Squash and rebase the master branch

`git rebase --root -i`

> View commits from between tags

`git log v0.0.2..HEAD`

### tailscale

`sudo tailscale up --accept-routes`

### ngrok

`ngrok http https://localhost:8081`
