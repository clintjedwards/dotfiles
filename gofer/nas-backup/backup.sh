#!/usr/bin/env bash
# Backs up nas to Google Cloud Storage with restic. Runs as the restic user on nas; see main.go for setup.
set -euo pipefail

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcs-key.json"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic-password"
export RESTIC_REPOSITORY="gs:production-161206-cold-backups:/"
# There's no terminal, so restic stays quiet unless this is set. Once a minute is enough to see it's moving.
export RESTIC_PROGRESS_FPS=0.0167

RESTIC="$HOME/bin/restic"
PATHS=(/mnt/safe /mnt/media/tvshows /mnt/media/movies)

# reencode works on the same disks and creates and deletes files under /mnt/safe as it goes, so the two shouldn't
# overlap. Holding its lock makes reencode refuse to start while we run. We only open the lock if it already exists;
# with protected_regular, a lock file we created in /tmp would stop reencode from opening it.
if [ -e /tmp/reencode.lock ]; then
  exec 9</tmp/reencode.lock
  if ! flock -n 9; then
    echo "ERROR: reencode is running; run this again once it's done."
    exit 1
  fi
fi

if ! "$RESTIC" self-update; then
  echo "WARN: self-update failed; continuing with $("$RESTIC" version)"
fi

# Exit code 3 means the snapshot was saved but some files couldn't be read. That's worth failing the run over so
# it gets looked at, but the check below should still happen.
rc=0
"$RESTIC" backup --verbose --option gs.connections=10 --exclude '*.xchr.tmp.*' "${PATHS[@]}" || rc=$?
case "$rc" in
  0) ;;
  3) echo "WARN: Snapshot saved, but some files couldn't be read; see above." ;;
  *) echo "ERROR: Backup failed."; exit "$rc" ;;
esac

# Only checks the repo's structure. --read-data would download everything, which costs money on cold storage.
if ! "$RESTIC" check; then
  echo "ERROR: Repository check failed."
  exit 1
fi

exit "$rc"
