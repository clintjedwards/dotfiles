#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <input_file|input_dir> <output_dir>"
  exit 1
fi

INPUT_PATH="$1"
OUTDIR="$2"
mkdir -p "$OUTDIR"

trap 'echo; echo "Interrupted. No originals will be deleted."; exit 130' INT TERM

is_video() {
  case "${1,,}" in
    *.mkv|*.mp4|*.mov|*.avi|*.m4v|*.wmv|*.flv|*.ts|*.webm) return 0 ;;
    *) return 1 ;;
  esac
}

already_xchr() {
  case "${1,,}" in
    *.xchr.*) return 0 ;;    # any extension after .xchr
    *)        return 1 ;;
  esac
}

probe_duration_s() {
  local f="$1" d
  d=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 -- "$f" 2>/dev/null || true)
  d=${d%.*}
  echo "${d:-}"
}

get_video_codec() {
  ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
    -of csv=p=0 -- "$1" 2>/dev/null || true
}

decode_scan_ok() {
  local f="$1"
  if ffmpeg -v error -xerror -i "$f" -f null - -nostats -loglevel error >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

progress_bar() {
  local total="${1:-0}" key value seconds percent
  while IFS== read -r key value; do
    if [ "$key" = "out_time_ms" ]; then
      seconds=$(( value / 1000000 ))
      if (( total > 0 )); then
        percent=$(( seconds * 100 / total ))
        (( percent > 100 )) && percent=100
        printf "\rEncoding: %3d%% (%ds/%ds)" "$percent" "$seconds" "$total"
      else
        printf "\rEncoding: %ds elapsed" "$seconds"
      fi
    fi
  done
}

encode_one() {
  local in="$1" outdir="$2"

  if ! is_video "$in"; then
    echo "Skip (not video): $in"; return 0
  fi
  if already_xchr "$in"; then
    echo "Skip (already xchr): $in"; return 0
  fi

  local fname base out tmp
  fname="$(basename -- "$in")"
  base="${fname%.*}"
  out="$outdir/${base}.xchr.mkv"
  tmp="$(mktemp -p "$outdir" "${base}.xchr.tmp.XXXXXX.mkv")"

  if [ -e "$out" ]; then
    echo "Skip (output exists): $out"; return 0
  fi

  echo "Source: $in"
  echo "Target: $out"

  local src_dur dst_dur diff allowed
  src_dur="$(probe_duration_s "$in")"

  # --- New: skip re-encode if already HEVC ---
  vcodec="$(get_video_codec "$in")"
  if [ "$vcodec" = "hevc" ]; then
    echo "Source is already HEVC — remuxing instead of re-encoding."
    (
      ffmpeg -y -i "$in" -map "0:v?" -map "0:a?" -map "0:s?" -c copy \
        -f matroska -progress - -nostats -loglevel error -- "$tmp"
    ) | progress_bar "${src_dur:-0}"
    echo
  else
    (
      ffmpeg -y -i "$in" -map "0:v?" -map "0:a?" -map "0:s?" -c:v libx265 -crf 23 -c:a copy \
        -f matroska -progress - -nostats -loglevel error -- "$tmp"
    ) | progress_bar "${src_dur:-0}"
    echo
  fi
  # ------------------------------------------

  if [ ! -s "$tmp" ]; then
    echo "ERROR: Temp output missing or empty: $tmp"
    rm -f -- "$tmp"; return 1
  fi

  dst_dur="$(probe_duration_s "$tmp")"
  if [ -n "${src_dur:-}" ] && [ -n "${dst_dur:-}" ] && [ "${src_dur:-0}" -gt 0 ]; then
    diff=$(( src_dur > dst_dur ? src_dur - dst_dur : dst_dur - src_dur ))
    allowed=$(( src_dur / 33 )); (( allowed < 2 )) && allowed=2
    if (( diff > allowed )); then
      echo "ERROR: Duration mismatch (src=${src_dur}s, dst=${dst_dur}s, diff=${diff}s > allowed=${allowed}s)"
      rm -f -- "$tmp"; return 1
    fi
  else
    echo "WARN: Could not verify durations; continuing with decode scan."
  fi

  if ! decode_scan_ok "$tmp"; then
    echo "ERROR: Decode scan failed: $tmp"
    rm -f -- "$tmp"; return 1
  fi

  mv -- "$tmp" "$out"
  chmod 0777 "$out"
  sync -f "$outdir" 2>/dev/null || true

  if [ -s "$out" ]; then
    echo "Verified output present. Deleting original: $in"
    rm -v -- "$in"
  else
    echo "ERROR: Final output missing after move; NOT deleting original."
    return 1
  fi

  echo "Done -> $out"
  return 0
}

if [ -f "$INPUT_PATH" ]; then
  encode_one "$INPUT_PATH" "$OUTDIR"
elif [ -d "$INPUT_PATH" ]; then
  shopt -s nullglob
  for f in "$INPUT_PATH"/*; do
    [ -f "$f" ] || continue
    encode_one "$f" "$OUTDIR" || echo "Failed on: $f"
  done
  shopt -u nullglob
else
  echo "ERROR: Not a file or directory: $INPUT_PATH"
  exit 1
fi
