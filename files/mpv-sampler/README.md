# mpv-sampler

Plays random clips, 200 seconds each, from a folder of videos and images, one
after another. Every clip starts at a random point in its file, so you get a
running sample of the whole collection instead of watching files start to
finish.

It also has a `watch` mode for the opposite: going through every file in
full, in a shuffled order that remembers where you got to.

## Setup

`install.sh` links `mpv-sampler` into `~/.bin`, which is on the PATH. It
needs `mpv` and `ffprobe` (which comes with mpv's `ffmpeg` dependency).

The folders it plays from are listed in [`directories`](directories), one per
line. Only files directly inside each folder are used; subfolders aren't
searched. It picks up `.mkv`, `.mp4`, `.avi`, `.mov` and `.webm` videos, and
`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif` and `.bmp` images. Hidden files are
skipped.

## Running it

```sh
mpv-sampler              # open mpv and play one clip from every file, shuffled
mpv-sampler update       # re-scan the folders; run after adding or removing files
mpv-sampler mix DIR...   # play clips from just these folders, for one session
mpv-sampler watch        # play every file in full, picking up where you left off
mpv-sampler watch --reshuffle   # forget watch progress and start a new shuffle
```

The first run scans everything before opening mpv, which takes a while on the
NAS. After that, `mpv-sampler` opens straight away using the last scan, so new
files don't show up until you run `mpv-sampler update`.

`mix` is for when you want a session focused on a few folders, which don't
have to be in `directories`. It doesn't touch the main scan, so `f` inside a
mix session switches to the whole library.

## Watching everything

`mpv-sampler watch` plays the whole library one file at a time, start to
finish, in a shuffled order, so over time you see all of it. Images are
included and show for 30 seconds each.

Quit whenever you like. The next `watch` opens the same file at the same
spot. Each file you finish or skip moves you along. Once you've been through
everything, the next `watch` shuffles a new order and starts again from the
first file. `watch --reshuffle` does that right away, throwing out the
current order and progress.

Files added part way through a pass (after an `update`) go on the end of the
current order, so you still see them this pass. Deleted files are skipped.

None of the sampler keys apply here, since you're watching whole files. mpv's
usual keys work, plus the arrow keys from `files/mpv/input.conf`: `→` or
`Enter` for the next file, `←` for the previous one, `↑`/`↓` to seek a minute
and `Shift+↑`/`Shift+↓` to seek 10 seconds. `U` still uploads to weow. The
order and progress are kept in `~/.cache/mpv-sampler/watch/`.

## Keys inside mpv

| Key           | What it does                                       |
| ------------- | -------------------------------------------------- |
| `f`, `F`      | Reshuffle: one new clip from every file            |
| `r`           | Jump to a different random point in this file      |
| `c`           | Clear the playlist                                 |
| `Space`       | Pause                                              |
| `Enter`, `→`  | Next clip                                          |
| `←`           | Previous clip                                      |
| `↑`, `↓`      | Seek 60 seconds forward or back within the clip    |
| `Shift+↑/↓`   | Seek 10 seconds forward or back within the clip    |
| `U`, then `y` | Upload this file to weow (see below)               |

Images show for 30 seconds. Files shorter than 200 seconds play in full, and
`r` doesn't do anything on them.

Apart from `U`, these keys only apply in mpv windows opened by `mpv-sampler`.
Opening a video in mpv any other way gets the normal mpv keys, plus `U` and
the arrow keys from `files/mpv/input.conf` (same as above, except the seeks
aren't limited to a clip).

## How it stays fast

To pick a random start point, it has to know every file's length before
playback starts, and running `ffprobe` on thousands of files over the network
is slow. So each file's length is saved in `~/.cache/mpv-sampler/meta.tsv`
along with its size and modification time, and a file is only probed again if
one of those changes. A scan where nothing changed is just a folder listing.

`~/.cache/mpv-sampler/library.txt` is the list of files and lengths from the
last `update`, which is what `f`, `F`, plain `mpv-sampler` and `watch` play
from.
Neither file belongs in this repo, since they list every file name.

## When something's wrong

- **"no duration for ..., skipping it"**: ffprobe couldn't read that file,
  usually because it's corrupt or only partly copied. It's left out of the
  playlist and gets checked again on every scan until it's fixed or removed.
- **A clip freezes at the end instead of moving on**: that's the problem the
  clip length cap and the bounded `↑`/`↓` seek are there to prevent. If it
  happens, the cached length for that file is probably wrong; touching the
  file (or deleting `meta.tsv`) makes the next `update` probe it again.
- **Nothing plays**: run `mpv-sampler update` in a terminal and read the
  output. The usual cause is the NAS not being mounted.

## Uploading to weow

`upload-to-weow` (in `files/`) copies files to `/mnt/safe/weow`. There are
three ways to run it:

- **In mpv**: press `U` (Shift+U), then `y` to confirm, to upload the file
  that's playing. The prompt names the file and gives up after 10 seconds, or
  when you press `n`, so a stray keypress can't upload anything. This works
  in every mpv window, not just the sampler. In the sampler it uploads the
  whole source file, not just the clip. The result shows on screen when the
  copy finishes, and mpv keeps playing in the meantime. The key comes from
  `files/mpv/upload-to-weow.lua`, which `install.sh` links into
  `~/.config/mpv/scripts`.
- **In Thunar**: right-click one or more files and pick "Upload to weow".
- **In a terminal**: `upload-to-weow FILE...`

It never overwrites anything. If any of the files already exists in weow, it
says which one and copies nothing, so a sampler session playing from weow
itself will just tell you the file is already there. Results also show up as
a desktop notification. Files are copied under a hidden name and renamed when
done, so a copy that fails partway never looks like a finished file.
