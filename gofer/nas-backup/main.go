package main

import (
	_ "embed"
	"log"

	sdk "github.com/clintjedwards/gofer/sdk/go/config"
)

// Runs over ssh on nas, which has the pools mounted, so gofer never needs the restic password or the GCS key.
//
//go:embed backup.sh
var backupScript string

// Everything being backed up is world-readable, so this doesn't need root.
const target = "restic@nas.clintjedwards.home"

const script = `
set -eu
apk add --no-cache openssh-client >/dev/null

test -n "$SSH_KEY" || { echo "SSH_KEY is not set"; exit 1; }
test -n "$KNOWN_HOSTS" || { echo "KNOWN_HOSTS is not set"; exit 1; }

dir=$(mktemp -d)
printf '%s\n' "$SSH_KEY" > "$dir/key"
printf '%s\n' "$KNOWN_HOSTS" > "$dir/known_hosts"
chmod 600 "$dir/key"

# The script is sent over stdin so nas always runs this version of it.
printf '%s' "$BACKUP_SCRIPT" | ssh -i "$dir/key" \
  -o BatchMode=yes \
  -o UserKnownHostsFile="$dir/known_hosts" \
  -o StrictHostKeyChecking=yes \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=10 \
  "$TARGET" bash -s
`

// Setup:
//
//	ssh-keygen -t ed25519 -N '' -C gofer-nas-backup -f ./gofer_nas_backup
//	gofer up ./gofer/nas-backup
//	gofer secret pipeline put nas-backup ssh-key @ < ./gofer_nas_backup
//	ssh-keyscan -t ed25519 nas.clintjedwards.home | gofer secret pipeline put nas-backup known-hosts @
//	gofer pipeline subscribe nas-backup cron every-six-months -s expression="0 10 15-21 2,8 4 *"
//
// On nas, the restic user has the restic binary in ~/bin (kept current by restic self-update), the GCS key in
// ~/.config/gcs-key.json and the repo password in ~/.config/restic-password, all only readable by restic. Put
// ./gofer_nas_backup.pub in its authorized_keys, prefixed with restrict,from="10.0.1.15".
//
// reencode runs every Monday, so this runs on the third Thursday of Feb and Aug to stay out of its way. Cron fields
// all have to match, so the 15-21 day range plus Thursday picks out exactly one day. Cron is UTC, so that's 3 or 4am
// MT depending on daylight time.
func main() {
	err := sdk.NewPipeline("nas-backup", "NAS Backup").
		Description("Backs up nas to Google Cloud Storage with restic.").
		Parallelism(1).
		Tasks(
			sdk.NewTask("backup", "alpine:3").
				Description("Run backup.sh on nas.").
				Command("sh", "-c", script).
				Variables(map[string]string{
					"SSH_KEY":       sdk.PipelineSecret("ssh-key"),
					"KNOWN_HOSTS":   sdk.PipelineSecret("known-hosts"),
					"TARGET":        target,
					"BACKUP_SCRIPT": backupScript,
				}),
		).Finish()
	if err != nil {
		log.Fatal(err)
	}
}
