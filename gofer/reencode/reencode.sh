#!/usr/bin/env bash
# Re-encodes videos to HEVC. Originals are only deleted once the output passes every check.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <input_file|input_dir> <output_dir>"
  exit 1
fi

INPUT_PATH="$1"
OUTDIR="$2"
mkdir -p "$OUTDIR"

# Encodes that don't shrink by at least this much are thrown away and skipped on later runs.
MIN_SAVINGS_PCT=10
SKIP_LIST_NAME=".reencode-skip"

CURRENT_TMP=""
TOTAL_BYTES_BEFORE=0
TOTAL_BYTES_AFTER=0
# Listed again in the summary, since the error itself is easy to lose in a long log.
FAILED=()

cleanup_tmp() {
  if [ -n "$CURRENT_TMP" ]; then
    rm -f -- "$CURRENT_TMP" 2>/dev/null || true
    CURRENT_TMP=""
  fi
}
trap 'echo; echo "Interrupted. No originals will be deleted."; cleanup_tmp; exit 130' INT TERM
# A dropped ssh connection; nowhere left to print to.
trap 'cleanup_tmp; exit 129' HUP
trap 'cleanup_tmp; exit 141' PIPE
trap 'cleanup_tmp' EXIT

exec 9>/tmp/reencode.lock
if ! flock -n 9; then
  echo "ERROR: Another reencode is already running."
  exit 1
fi

# Encoding uses every core, so stay out of the way of everything else.
NICE=(nice -n 19)
command -v ionice >/dev/null && NICE+=(ionice -c 3)

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

on_skip_list() {
  local list
  list="$(dirname -- "$1")/$SKIP_LIST_NAME"
  [ -f "$list" ] && grep -Fxq -- "$(basename -- "$1")" "$list"
}

probe_duration_s() {
  local f="$1" d
  d=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 -- "$f" 2>/dev/null || true)
  d=${d%.*}
  echo "${d:-}"
}

# Capital V skips cover art.
get_video_codec() {
  ffprobe -v error -select_streams V:0 -show_entries stream=codec_name \
    -of csv=p=0 -- "$1" 2>/dev/null || true
}

get_sar() {
  ffprobe -v error -select_streams V:0 -show_entries stream=sample_aspect_ratio \
    -of csv=p=0 -- "$1" 2>/dev/null || true
}

# Prints the displayed aspect ratio, like 1.7778, from frame size, pixel shape and rotation. ffprobe's own
# display_aspect_ratio is often missing.
probe_dar() {
  ffprobe -v error -select_streams V:0 \
    -show_entries stream=width,height,sample_aspect_ratio:stream_side_data=rotation \
    -of default=noprint_wrappers=1 -- "$1" 2>/dev/null |
    awk -F= '
      $1 == "width" { w = $2 }
      $1 == "height" { h = $2 }
      $1 == "sample_aspect_ratio" { split($2, s, ":"); if (s[1] + 0 > 0 && s[2] + 0 > 0) { sn = s[1]; sd = s[2] } }
      $1 == "rotation" { r = $2 }
      END {
        if (w <= 0 || h <= 0) exit
        dar = (w * (sn ? sn : 1)) / (h * (sd ? sd : 1))
        if (r % 180 != 0) dar = 1 / dar
        printf "%.4f\n", dar
      }'
}

# Within 1%, to allow for rounding.
same_dar() {
  awk -v a="$1" -v b="$2" 'BEGIN { d = a - b; if (d < 0) d = -d; exit !(d <= a * 0.01) }'
}

decode_scan_ok() {
  "${NICE[@]}" ffmpeg -nostdin -v error -xerror -i "$1" -f null - >/dev/null 2>&1
}

# A progress bar on a terminal; a line every 10% otherwise, so logs stay small.
progress_bar() {
  local total="${1:-0}" key value seconds percent last=-1
  while IFS== read -r key value; do
    [ "$key" = "out_time_us" ] || continue
    [[ "$value" =~ ^[0-9]+$ ]] || continue
    seconds=$(( value / 1000000 ))
    if (( total > 0 )); then
      percent=$(( seconds * 100 / total ))
      (( percent > 100 )) && percent=100
      if [ -t 1 ]; then
        printf "\rEncoding: %3d%% (%ds/%ds)" "$percent" "$seconds" "$total"
      elif (( percent / 10 > last )); then
        last=$(( percent / 10 ))
        printf "Encoding: %3d%% (%ds/%ds)\n" "$percent" "$seconds" "$total"
      fi
    elif [ -t 1 ]; then
      printf "\rEncoding: %ds elapsed" "$seconds"
    fi
  done
  [ -t 1 ] && echo
  return 0
}

bytes_to_human() {
  awk -v b="$1" 'BEGIN {
    if (b >= 1073741824) printf "%.2f GiB", b/1073741824
    else if (b >= 1048576) printf "%.2f MiB", b/1048576
    else printf "%.2f KiB", b/1024
  }'
}

# Copies the original's owner, mode and timestamps so Samba users can still manage the file.
finish_output() {
  local in="$1" out="$2"
  chown --reference="$in" -- "$out" 2>/dev/null || true
  chmod --reference="$in" -- "$out"
  touch --reference="$in" -- "$out"
}

output_path() {
  local fname
  fname="$(basename -- "$1")"
  echo "$2/${fname%.*}.xchr.mkv"
}

# Decided up front so the progress counts only include files that will actually be worked on.
needs_encode() {
  local in="$1" outdir="$2" out

  if ! is_video "$in"; then
    return 1
  fi
  if already_xchr "$in"; then
    return 1
  fi
  if on_skip_list "$in"; then
    echo "Skip (on skip list): $in"; return 1
  fi

  out="$(output_path "$in" "$outdir")"
  if [ -e "$out" ]; then
    echo "Skip (output exists): $out"; return 1
  fi
  return 0
}

encode_one() {
  local in="$1" outdir="$2"

  local fname base out
  fname="$(basename -- "$in")"
  base="${fname%.*}"
  out="$(output_path "$in" "$outdir")"

  echo "Source: $in"
  echo "Target: $out"

  local vcodec src_dur src_size src_dar
  vcodec="$(get_video_codec "$in")"
  if [ -z "$vcodec" ]; then
    echo "ERROR: No video stream found"; return 1
  fi
  src_dur="$(probe_duration_s "$in")"
  src_size="$(stat -c%s -- "$in")"
  src_dar="$(probe_dar "$in")"

  # An HEVC mkv only needs renaming.
  if [ "$vcodec" = "hevc" ] && [[ "${in,,}" == *.mkv ]] && [ "$(dirname -- "$in")" -ef "$outdir" ]; then
    echo "Source is already HEVC in mkv; renaming."
    mv -n -- "$in" "$out"
    echo "Done -> $out"
    return 0
  fi

  CURRENT_TMP="$(mktemp -p "$outdir" "${base}.xchr.tmp.XXXXXX.mkv")"

  # mp4 subtitles (mov_text) can't go into mkv as is; everything else is copied.
  local sub_codec=copy
  if ffprobe -v error -select_streams s -show_entries stream=codec_name -of csv=p=0 -- "$in" 2>/dev/null |
      grep -qx mov_text; then
    sub_codec=srt
  fi

  local args=(-map "0:V:0" -map "0:a?" -map "0:s?" -map "0:t?" -c copy -c:s "$sub_codec")
  if [ "$vcodec" = "hevc" ]; then
    echo "Source is already HEVC; remuxing instead of re-encoding."
  else
    # Set the pixel shape explicitly; losing it is what squashed some videos.
    local sar
    sar="$(get_sar "$in")"
    args+=(-c:v libx265 -crf 23 -x265-params log-level=error)
    if [[ "$sar" =~ ^[1-9][0-9]*:[1-9][0-9]*$ ]] && [ "$sar" != "1:1" ]; then
      args+=(-vf "setsar=${sar/://}")
    fi
  fi

  # Stops ffmpeg giving up on files with sparse subtitles.
  if ! "${NICE[@]}" ffmpeg -nostdin -y -i "$in" "${args[@]}" -max_muxing_queue_size 9999 \
      -f matroska -progress pipe:1 -nostats -loglevel error -- "$CURRENT_TMP" |
      progress_bar "${src_dur:-0}"; then
    echo "ERROR: ffmpeg failed"
    cleanup_tmp; return 1
  fi

  if [ ! -s "$CURRENT_TMP" ]; then
    echo "ERROR: Temp output missing or empty: $CURRENT_TMP"
    cleanup_tmp; return 1
  fi

  local dst_dur dst_dar diff allowed
  dst_dur="$(probe_duration_s "$CURRENT_TMP")"
  if [ -n "${src_dur:-}" ] && [ -n "${dst_dur:-}" ] && [ "${src_dur:-0}" -gt 0 ]; then
    diff=$(( src_dur > dst_dur ? src_dur - dst_dur : dst_dur - src_dur ))
    allowed=$(( src_dur / 33 )); (( allowed < 2 )) && allowed=2
    if (( diff > allowed )); then
      echo "ERROR: Duration mismatch (src=${src_dur}s, dst=${dst_dur}s, diff=${diff}s > allowed=${allowed}s)"
      cleanup_tmp; return 1
    fi
  else
    echo "WARN: Could not verify durations; continuing with decode scan."
  fi

  dst_dar="$(probe_dar "$CURRENT_TMP")"
  if [ -n "$src_dar" ] && [ -n "$dst_dar" ] && ! same_dar "$src_dar" "$dst_dar"; then
    echo "ERROR: Aspect ratio changed (src=${src_dar}, dst=${dst_dar})"
    cleanup_tmp; return 1
  fi

  local dst_size
  dst_size="$(stat -c%s -- "$CURRENT_TMP")"
  if [ "$vcodec" != "hevc" ] && (( dst_size * 100 > src_size * (100 - MIN_SAVINGS_PCT) )); then
    echo "Not worth it ($(bytes_to_human "$src_size") -> $(bytes_to_human "$dst_size")); keeping the original."
    echo "$fname" >> "$(dirname -- "$in")/$SKIP_LIST_NAME"
    cleanup_tmp; return 0
  fi

  if ! decode_scan_ok "$CURRENT_TMP"; then
    echo "ERROR: Decode scan failed: $CURRENT_TMP"
    cleanup_tmp; return 1
  fi

  mv -- "$CURRENT_TMP" "$out"
  CURRENT_TMP=""
  finish_output "$in" "$out"
  sync -f "$outdir" 2>/dev/null || true

  if [ ! -s "$out" ]; then
    echo "ERROR: Final output missing after move; NOT deleting original."
    return 1
  fi

  rm -- "$in"
  echo "Verified output; deleted original."

  TOTAL_BYTES_BEFORE=$(( TOTAL_BYTES_BEFORE + src_size ))
  TOTAL_BYTES_AFTER=$(( TOTAL_BYTES_AFTER + dst_size ))
  printf "Space: %s -> %s\n" "$(bytes_to_human "$src_size")" "$(bytes_to_human "$dst_size")"
  echo "Done -> $out"
  return 0
}

print_summary() {
  if (( TOTAL_BYTES_BEFORE > 0 )); then
    local saved=$(( TOTAL_BYTES_BEFORE - TOTAL_BYTES_AFTER ))
    echo
    echo "--- Summary ---"
    printf "Before: %s\n" "$(bytes_to_human "$TOTAL_BYTES_BEFORE")"
    printf "After:  %s\n" "$(bytes_to_human "$TOTAL_BYTES_AFTER")"
    printf "Saved:  %s (%d%%)\n" "$(bytes_to_human "$saved")" "$(( saved * 100 / TOTAL_BYTES_BEFORE ))"
  fi
  if (( ${#FAILED[@]} > 0 )); then
    echo "Failed: ${#FAILED[@]} file(s)"
    printf '  %s\n' "${FAILED[@]}"
  fi
}

run_one() {
  if ! encode_one "$1" "$2"; then
    echo "Failed on: $1"
    FAILED+=("$1")
  fi
}

if [ -f "$INPUT_PATH" ]; then
  if needs_encode "$INPUT_PATH" "$OUTDIR"; then
    run_one "$INPUT_PATH" "$OUTDIR"
  fi
elif [ -d "$INPUT_PATH" ]; then
  # We hold the lock, so these are from a killed run.
  find "$OUTDIR" -maxdepth 1 -name '*.xchr.tmp.*.mkv' -type f -delete
  shopt -s nullglob
  queue=()
  for f in "$INPUT_PATH"/*; do
    [ -f "$f" ] || continue
    needs_encode "$f" "$OUTDIR" && queue+=("$f")
  done
  shopt -u nullglob

  # Long runs are hard to judge otherwise. Failed files count as finished.
  total=${#queue[@]}
  echo "Files to process: $total"
  finished=0
  for f in "${queue[@]}"; do
    echo
    echo "=== File $(( finished + 1 ))/$total ==="
    run_one "$f" "$OUTDIR"
    finished=$(( finished + 1 ))
    echo "Progress: $finished finished, $(( total - finished )) to go, $total total"
  done
else
  echo "ERROR: Not a file or directory: $INPUT_PATH"
  exit 1
fi

print_summary
(( ${#FAILED[@]} == 0 ))
