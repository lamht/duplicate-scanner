
#!/bin/bash

set -uo pipefail

REPORT="/reports/duplicates-$(date +%Y%m%d-%H%M%S).csv"
TMP=$(mktemp)

trap 'rm -f "$TMP"' EXIT

echo "Scanning video files..."

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
    hash=$(sha256sum -- "$file" | cut -d ' ' -f 1)
    size=$(stat -c '%s' -- "$file")

    printf '%s,%s,%s\n' "$hash" "$size" "$file"
done > "$TMP"

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

echo "================================"
echo "Scan completed!"
echo "Report: $REPORT"
echo "================================"
