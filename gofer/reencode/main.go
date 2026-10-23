package main

import (
	_ "embed"
	"log"
	"strings"

	sdk "github.com/clintjedwards/gofer/sdk/go/config"
)

// Runs over ssh on nas, which has the files on local disk, so no video crosses the network.
//
//go:embed reencode.sh
var reencodeScript string

// /mnt/safe/weow on nas is /triple_mirror/weow on the host. weow has the sticky bit set, so only its owner (home) can
// delete the originals.
const target = "home@nas.clintjedwards.home"

var mediaPaths = []string{
	"/mnt/safe/weow",
}

const script = `
set -eu
apk add --no-cache openssh-client >/dev/null

test -n "$SSH_KEY" || { echo "SSH_KEY is not set"; exit 1; }
test -n "$KNOWN_HOSTS" || { echo "KNOWN_HOSTS is not set"; exit 1; }

dir=$(mktemp -d)
printf '%s\n' "$SSH_KEY" > "$dir/key"
printf '%s\n' "$KNOWN_HOSTS" > "$dir/known_hosts"
chmod 600 "$dir/key"

# Quote each path for the remote shell.
quoted=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  quoted="$quoted '$(printf '%s' "$p" | sed "s/'/'\\\\''/g")'"
done <<EOF
$MEDIA_PATHS
EOF

# The script is sent over stdin so nas always runs this version of it.
remote='f=$(mktemp) || exit 1
cat > "$f"
rc=0
for p in '"$quoted"'; do
  bash "$f" "$p" "$p" </dev/null || rc=1
done
rm -f "$f"
exit $rc'

printf '%s' "$REENCODE_SCRIPT" | ssh -i "$dir/key" \
  -o BatchMode=yes \
  -o UserKnownHostsFile="$dir/known_hosts" \
  -o StrictHostKeyChecking=yes \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=10 \
  "$TARGET" "$remote"
`

// Setup:
//
//	ssh-keygen -t ed25519 -N '' -C gofer-reencode -f ./gofer_reencode
//	gofer up ./gofer/reencode
//	gofer secret pipeline put reencode ssh-key @ < ./gofer_reencode
//	ssh-keyscan -t ed25519 nas.clintjedwards.home | gofer secret pipeline put reencode known-hosts @
//	gofer pipeline subscribe reencode cron every-four-months -s expression="0 10 1 1,5,9 * *"
//
// Put ./gofer_reencode.pub in home's authorized_keys on nas, prefixed with restrict,from="10.0.1.15". Cron is UTC,
// so this runs at 3 or 4am MT depending on daylight time.
func main() {
	err := sdk.NewPipeline("reencode", "Re-encode Media").
		Description("Re-encodes videos on nas to HEVC to save space.").
		Parallelism(1).
		Tasks(
			sdk.NewTask("reencode", "alpine:3").
				Description("Run reencode.sh on nas.").
				Command("sh", "-c", script).
				Variables(map[string]string{
					"SSH_KEY":         sdk.PipelineSecret("ssh-key"),
					"KNOWN_HOSTS":     sdk.PipelineSecret("known-hosts"),
					"TARGET":          target,
					"MEDIA_PATHS":     strings.Join(mediaPaths, "\n"),
					"REENCODE_SCRIPT": reencodeScript,
				}),
		).Finish()
	if err != nil {
		log.Fatal(err)
	}
}
