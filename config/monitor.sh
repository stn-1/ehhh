#!/bin/bash
# Run from the project root: bash config/monitor.sh

watch -n 5 '
echo "=== Recon Pipeline Status ==="
echo ""
echo "Input domains : $(grep -v "^#" inputs/domains.txt 2>/dev/null | grep -v "^$" | wc -l | tr -d " ")"
echo "Summaries done: $(ls outputs/*_summary.txt 2>/dev/null | wc -l | tr -d " ")"
echo ""
echo "Latest alive subdomain files:"
ls -lht outputs/*_alive.txt 2>/dev/null | head -5
echo ""
echo "Latest web service files:"
ls -lht outputs/*_websites.txt 2>/dev/null | head -5
'
