#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-self-healing-infra.service}"
RESULTS_FILE="docs/failure-tests.csv"

mkdir -p docs

if [[ ! -f "$RESULTS_FILE" ]]; then
    echo "timestamp,test_id,failure,recovery_mechanism,recovery_time_seconds,manual_intervention,result" > "$RESULTS_FILE"
fi

sudo systemctl is-active --quiet "$SERVICE" || {
    echo "Service is not running."
    exit 1
}

OLD_PID=$(systemctl show -p MainPID --value "$SERVICE")

echo "Current PID: $OLD_PID"
echo "Killing service process..."

START=$(date +%s%3N)

sudo systemctl kill \
    --kill-who=main \
    --signal=SIGKILL \
    "$SERVICE"

NEW_PID=""

for i in {1..300}; do
    STATE=$(systemctl show -p ActiveState --value "$SERVICE")
    PID=$(systemctl show -p MainPID --value "$SERVICE")

    if [[ "$STATE" == "active" && "$PID" != "0" && "$PID" != "$OLD_PID" ]]; then
        NEW_PID="$PID"
        break
    fi

    sleep 0.1
done

END=$(date +%s%3N)

if [[ -n "$NEW_PID" ]]; then
    RECOVERY=$(awk -v s="$START" -v e="$END" 'BEGIN {printf "%.3f", (e-s)/1000}')
    TIMESTAMP=$(date -Is)

    echo "$TIMESTAMP,T1,SIGKILL application process,systemd Restart=always,$RECOVERY,none,PASS" >> "$RESULTS_FILE"

    echo
    echo "PASS"
    echo "Old PID: $OLD_PID"
    echo "New PID: $NEW_PID"
    echo "Recovery time: ${RECOVERY}s"
else
    TIMESTAMP=$(date -Is)

    echo "$TIMESTAMP,T1,SIGKILL application process,systemd Restart=always,,none,FAIL" >> "$RESULTS_FILE"

    echo
    echo "FAIL"
    echo "Service did not recover within 30 seconds."
    exit 1
fi
