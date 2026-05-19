#!/bin/bash

INPUT_FILE="/workspace/inputs/domains.txt"
MAX_PARALLEL=${MAX_PARALLEL:-3}

if [ ! -f "$INPUT_FILE" ]; then
    echo "[ERROR] inputs/domains.txt not found"
    exit 1
fi

DOMAINS=$(grep -v '^#' "$INPUT_FILE" | grep -v '^$')
TOTAL=$(echo "$DOMAINS" | wc -l | tr -d ' ')
echo "[INFO] Starting parallel scan — $TOTAL domains, $MAX_PARALLEL at a time"

process_domain() {
    local domain="$1"
    echo "[START] $domain"
    DOMAIN="$domain" /scripts/run_pipeline.sh
    echo "[DONE]  $domain"
}

export -f process_domain
export THREADS MAX_PARALLEL RUN_HTTPX WEBHOOK_URL OUTPUT_DIR

echo "$DOMAINS" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'process_domain "$@"' _ {}

echo "[INFO] All domains processed."
