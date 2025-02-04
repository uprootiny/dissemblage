#!/bin/bash
set -euo pipefail  # Strict mode: fail on errors, unset vars, or pipeline failures

### CONFIGURATION ###
REPO_DIR="/home/uprootiny/Feb2025/dissemblage"
LAST_RUN_FILE="$REPO_DIR/.last_report_run"
DEPLOY_LOG="/var/log/deploy_dissemblage.log"
GIT_LOG="$REPO_DIR/.git/logs/HEAD"
NGINX_CONF="/etc/nginx/sites-available/lab.dissemblage.art"
JS_DIR="$REPO_DIR/js"
NOW=$(date +%s)
COOLDOWN=300  # Minimum seconds between runs

### 🛑 Idempotency Check (Prevent Loops) ###
if [[ -f "$LAST_RUN_FILE" ]]; then
    LAST_RUN=$(cat "$LAST_RUN_FILE")
    if (( NOW - LAST_RUN < COOLDOWN )); then
        echo "🛑 Report was just run recently. Skipping."
        exit 0
    fi
fi
echo "$NOW" > "$LAST_RUN_FILE"

echo "🔎 Running Summary Report for Dissemblage"
echo "========================================="

### ✅ 1. Check Repository Health ###
echo "📂 Checking repository structure..."
MISSING=()
for item in README.md ROADMAP.md TODO.md deploy.sh iter.sh setup.sh index.xhtml js/ styles/; do
    [[ ! -e "$REPO_DIR/$item" ]] && MISSING+=("$item")
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "✅ All essential files are present."
else
    echo "⚠️ Missing files: ${MISSING[*]}"
fi

### ✅ 2. Git Status & Latest Commits ###
echo "🔄 Checking Git status..."
cd "$REPO_DIR"
if [[ ! -d .git ]]; then
    echo "❌ Not a Git repository!"
else
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "⚠️ Uncommitted changes detected:"
        git status --short
    else
        echo "✅ Working tree is clean."
    fi
    echo "🔍 Latest commits:"
    git log --oneline -n 5
fi

### ✅ 3. Deployment Logs & Errors ###
echo "📜 Reviewing latest deployment logs..."
if [[ -f "$DEPLOY_LOG" ]]; then
    tail -n 10 "$DEPLOY_LOG"
else
    echo "⚠️ Deployment log is missing."
fi

echo "🚨 Checking system errors..."
sudo journalctl -p 3 -n 5 --no-pager || echo "✅ No critical errors detected."

### ✅ 4. Nginx & Server Status ###
echo "🌐 Checking Nginx configuration..."
if sudo nginx -t &>/dev/null; then
    echo "✅ Nginx configuration is valid."
else
    echo "❌ Nginx configuration has errors!"
fi

echo "🔍 Checking if Nginx is running..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running."
else
    echo "❌ Nginx is NOT running!"
fi

### ✅ 5. JavaScript MVP Health Check ###
echo "🎨 Checking JavaScript MVP files..."
MISSING_JS=()
for file in chaoticFields.js voronoiGrowth.js waveInterference.js cellularAutomata.js fractalExpansion.js latticeTurbulence.js fluidDynamics.js algorithmicSpirals.js; do
    [[ ! -f "$JS_DIR/$file" ]] && MISSING_JS+=("$file")
done

if [[ ${#MISSING_JS[@]} -eq 0 ]]; then
    echo "✅ All MVP scripts are present."
else
    echo "⚠️ Missing MVP scripts: ${MISSING_JS[*]}"
fi

### ✅ 6. Outstanding Tasks in TODO.md ###
if [[ -f "$REPO_DIR/TODO.md" ]]; then
    echo "📌 Outstanding tasks from TODO.md:"
    grep -E "^\s*- \[ \]" "$REPO_DIR/TODO.md" || echo "✅ No outstanding tasks."
else
    echo "⚠️ TODO.md is missing."
fi

### ✅ 7. System Performance & Load Check ###
echo "📊 Checking system load..."
uptime

echo "📊 Memory Usage:"
free -h | grep "Mem"

echo "📊 Disk Usage:"
df -h | grep "/$"

### ✅ 8. Final Summary ###
echo "========================================="
echo "✅ Summary report complete!"
echo "📜 Logs checked, scripts verified, and services inspected."
echo "📂 Repository status: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")"
echo "🔍 Check detailed logs in $DEPLOY_LOG"


