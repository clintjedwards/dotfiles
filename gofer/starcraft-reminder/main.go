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
