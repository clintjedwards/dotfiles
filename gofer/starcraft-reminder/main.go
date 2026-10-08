package main

import (
	"log"

	sdk "github.com/clintjedwards/gofer/sdk/go/config"
)

const script = `
set -eu
apk add --no-cache curl jq tzdata >/dev/null

if [ "${FORCE:-false}" != "true" ] && [ "$(TZ=America/New_York date +%H)" != "18" ]; then
  echo "not 18:00 ET; skipping"
  exit 0
fi

test -n "$WEBHOOK" || { echo "WEBHOOK is not set"; exit 1; }

MESSAGE="Reminder for starcraft in 30 mins"
# <@88085639920119808> is the Discord user _yourself.
CTA="-# *I made this because fuck <@88085639920119808> in particular*"
# <@&801361771183996948> is the starcraftBoomers role, so the whole group gets pinged.
BODY=$(printf '<@&801361771183996948> %s\n\n%s' "$MESSAGE" "$CTA")

curl -sSf -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  --data "$(jq -n --arg c "$BODY" '{content: $c}')"
`

// Setup:
//
//	gofer up -d ./gofer/starcraft-reminder
//	printf '%s' "$DISCORD_WEBHOOK_URL" | gofer secret pipeline put starcraft-reminder discord-webhook @
//	gofer pipeline subscribe starcraft-reminder cron thursday_1830_et -s expression="30 22,23 * * 4 *"
//
// The cron extension only runs on UTC, so the expression fires at both 22:30 and 23:30 UTC on Thursday. That
// covers 18:30 ET in both EDT and EST, and the hour check at the top of the script drops whichever one isn't
// 18:00 ET. Use printf rather than echo for the secret; the CLI keeps a trailing newline and that breaks curl.
// To test it outside the schedule, skip the hour check with: gofer run start starcraft-reminder -v FORCE=true
func main() {
	err := sdk.NewPipeline("starcraft-reminder", "Starcraft Reminder").
		Description("Posts a 30 minute warning to Discord before Thursday starcraft at 19:00 ET.").
		Tasks(
			sdk.NewTask("post", "alpine:3").
				Description("Post the reminder to Discord.").
				Command("sh", "-c", script).
				Variables(map[string]string{
					"WEBHOOK": sdk.PipelineSecret("discord-webhook"),
				}),
		).Finish()
	if err != nil {
		log.Fatal(err)
	}
}
