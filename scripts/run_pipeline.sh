#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN=${DOMAIN:-$1}
INPUT_DIR="/workspace/inputs"
OUTPUT_DIR="/workspace/outputs"
THREADS=${THREADS:-50}
RUN_HTTPX=${RUN_HTTPX:-true}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

LOG_FILE="$OUTPUT_DIR/recon_${TIMESTAMP}.log"

log()     { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }
section() { echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE"; }
count()   { wc -l < "$1" 2>/dev/null | tr -d ' ' || echo "0"; }

if [ -z "$DOMAIN" ]; then
    if [ -f "$INPUT_DIR/domains.txt" ]; then
        DOMAINS=$(grep -v '^#' "$INPUT_DIR/domains.txt" | grep -v '^$')
        log "Loaded domains from inputs/domains.txt"
    else
        error "No domain provided. Set DOMAIN=example.com or create inputs/domains.txt"
        exit 1
    fi
else
    DOMAINS="$DOMAIN"
fi

run_step() {
    local label="$1"; shift
    local out="$1"; shift
    log "Running $label..."
    local start=$SECONDS
    "$@" && {
        local n; n=$(count "$out")
        log "✓ $label → $n results ($(( SECONDS - start ))s)"
    } || warn "$label exited with errors (partial results may exist)"
}

for TARGET in $DOMAINS; do
    section "========================================="
    section " Target: $TARGET"
    section "========================================="

    OUT="$OUTPUT_DIR/$TARGET"

    # ── Step 1: Subfinder ─────────────────────────────────
    run_step "Subfinder" "${OUT}_subfinder.txt" \
        subfinder -d "$TARGET" -silent -o "${OUT}_subfinder.txt"

    # ── Step 2: Assetfinder ───────────────────────────────
    run_step "Assetfinder" "${OUT}_assetfinder.txt" \
        bash -c "assetfinder --subs-only $TARGET > '${OUT}_assetfinder.txt'"

    # ── Step 3: Merge & deduplicate ───────────────────────
    log "Merging and deduplicating..."
    cat "${OUT}_subfinder.txt" "${OUT}_assetfinder.txt" 2>/dev/null \
        | sort -u > "${OUT}_all_subdomains.txt"
    TOTAL=$(count "${OUT}_all_subdomains.txt")
    log "✓ Unique subdomains: $TOTAL"

    # ── Step 4: DNS resolution via DNSx ──────────────────
    run_step "DNSx" "${OUT}_alive.txt" \
        dnsx -l "${OUT}_all_subdomains.txt" \
             -silent -resp-only -t "$THREADS" \
             -o "${OUT}_alive.txt"

    ALIVE=$(count "${OUT}_alive.txt")

    # ── Step 5: HTTP probing via HTTPx ────────────────────
    WEB=0
    if [ "$RUN_HTTPX" = "true" ]; then
        run_step "HTTPx" "${OUT}_websites.txt" \
            httpx -l "${OUT}_alive.txt" \
                  -silent -status-code -title -tech-detect \
                  -threads "$THREADS" \
                  -o "${OUT}_websites.txt"
        WEB=$(count "${OUT}_websites.txt")
    fi

    # ── Summary ────────────────────────────────────────────
    cat > "${OUT}_summary.txt" <<EOF
Recon Summary: $TARGET
Date         : $(date)
Subfinder    : $(count "${OUT}_subfinder.txt")
Assetfinder  : $(count "${OUT}_assetfinder.txt")
Total unique : $TOTAL
Alive (DNS)  : $ALIVE
Web services : $WEB
EOF

    section "-----------------------------------------"
    log "Summary for $TARGET:"
    cat "${OUT}_summary.txt" | tee -a "$LOG_FILE"
    section "-----------------------------------------"

    # ── Webhook notification ───────────────────────────────
    if [ -n "$WEBHOOK_URL" ]; then
        curl -sf -X POST -H "Content-Type: application/json" \
            -d "{\"text\":\"[$TARGET] Recon done — $ALIVE alive, $WEB web services\"}" \
            "$WEBHOOK_URL" || warn "Webhook notification failed"
    fi
done

section "========================================="
log "All targets done. Results in: $OUTPUT_DIR"
log "Log: $LOG_FILE"
section "========================================="

# Clean up result files older than 7 days
find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.txt" -mtime +7 -delete 2>/dev/null || true
