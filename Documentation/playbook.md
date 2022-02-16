### Backup NAS to google cloud

`gsutil -m -o GSUtil:parallel_composite_upload_threshold=150M cp -L /tmp/uploadlog -r /data gs://production-161206-cold-backups/`

### Setting up autorandr

https://github.com/phillipberndt/autorandr

> Get the current state of displays

`xrandr --current`

> Setup displays how you want them

`xrandr --output eDP1 --off && xrandr --output HDMI --primary --auto`

> Save them with autorandr and autorandr will auto detect when it is in a state that you've saved and run the correct command

`autorandr --save <name>`

> manually reload with

`autorandr --change`
