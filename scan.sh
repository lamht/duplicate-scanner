#!/bin/bash

set -uo pipefail

REPORT="/reports/duplicates-$(date +%Y%m%d-%H%M%S).csv"
TMP=$(mktemp)

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

trap 'rm -f "$TMP"' EXIT

if [[ ! -d /media ]]; then
    log "ERROR: Media directory /media does not exist"
    exit 1
fi

if [[ ! -d /reports || ! -w /reports ]]; then
    log "ERROR: Report directory /reports is missing or not writable"
    exit 1
fi

log "Scan started"
log "Media directory: /media"
log "Report file: $REPORT"
log "Finding video files..."

processed=0

find /media -type f \
  \( -iname '*.mkv' \
  -o -iname '*.mp4' \
  -o -iname '*.avi' \
  -o -iname '*.mov' \
  -o -iname '*.wmv' \
  -o -iname '*.m4v' \
  -o -iname '*.ts' \
  -o -iname '*.webm' \
  -o -iname '*.mpg' \
  -o -iname '*.mpeg' \) \
  -print0 |
while IFS= read -r -d '' file; do
    processed=$((processed + 1))
    log "[$processed] Hashing file: $file"

    if ! hash=$(sha256sum -- "$file" | cut -d ' ' -f 1); then
        log "ERROR: Failed to calculate SHA256: $file"
        continue
    fi

    if ! size=$(stat -c '%s' -- "$file"); then
        log "ERROR: Failed to read file size: $file"
        continue
    fi

    if (( processed == 1 || processed % 100 == 0 )); then
        log "Hashed $processed video file(s)..."
    fi

    log "[$processed] SHA256: $hash; size: $size bytes"
    printf '%s,%s,%s\n' "$hash" "$size" "$file"
done > "$TMP"

file_count=$(wc -l < "$TMP")
log "Hashed $file_count video file(s)"
log "Generating duplicate report..."

{
    echo '"SHA256","SIZE_BYTES","FILE_PATH"'

    awk -F ',' '
    BEGIN { OFS="," }
    {
        count[$1]++
        lines[$1] = lines[$1] sprintf("\"%s\",%s,\"%s\"\n", $1, $2, substr($0, index($0,$3)))
    }
    END {
        for (hash in count) {
            if (count[hash] > 1)
                printf "%s", lines[hash]
        }
    }' "$TMP"

} > "$REPORT"

log "Scan completed"
log "Report saved to: $REPORT"
