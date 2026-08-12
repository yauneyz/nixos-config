#!/usr/bin/env bash
set -eu

cpu_usage="$({ LC_ALL=C top -bn1 || true; } | awk '/^%?Cpu/ { idle=$8; gsub(/,/, ".", idle); printf "%d", 100-idle; exit }')"
memory_usage="$(free -m | awk 'NR == 2 && $2 > 0 { printf "%d", 100*($2-$7)/$2 }')"
disk_usage="$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"

printf 'cpu=%s\nmem=%s\ndisk=%s\n' "${cpu_usage:-0}" "${memory_usage:-0}" "${disk_usage:-0}"
