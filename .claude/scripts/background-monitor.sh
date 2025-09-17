#!/bin/bash

# CC-Scrum Background Process Monitor
# Monitors development processes and provides self-healing capabilities

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.claude/logs/background-monitor.log"
PID_FILE="$PROJECT_ROOT/.claude/pids/monitor.pid"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PID_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if monitor is already running
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "Background monitor already running (PID: $(cat "$PID_FILE"))"
    exit 1
fi

# Store current PID
echo $$ > "$PID_FILE"

log "🚀 CC-Scrum Background Monitor started"

# Cleanup function
cleanup() {
    log "🛑 Background monitor stopping..."
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Process monitoring configuration
declare -A PROCESSES=(
    ["dev_server"]="npm run dev"
    ["test_watch"]="npm run test:watch"
    ["typecheck_watch"]="npm run typecheck:watch"
)

declare -A PROCESS_PIDS=()
declare -A RESTART_COUNTS=()

# Health check function
check_process_health() {
    local name="$1"
    local command="$2"

    # Check if process is running
    if [[ -n "${PROCESS_PIDS[$name]:-}" ]] && kill -0 "${PROCESS_PIDS[$name]}" 2>/dev/null; then
        return 0  # Process is healthy
    else
        return 1  # Process is not running
    fi
}

# Start process function
start_process() {
    local name="$1"
    local command="$2"

    log "🔄 Starting $name: $command"

    # Change to project root
    cd "$PROJECT_ROOT"

    # Start process in background
    eval "$command" > "$PROJECT_ROOT/.claude/logs/${name}.log" 2>&1 &
    local pid=$!

    PROCESS_PIDS[$name]=$pid
    log "✅ Started $name (PID: $pid)"

    # Initialize restart count
    RESTART_COUNTS[$name]=0
}

# Restart process function
restart_process() {
    local name="$1"
    local command="$2"

    # Increment restart count
    RESTART_COUNTS[$name]=$((${RESTART_COUNTS[$name]} + 1))

    # Check restart limit (max 5 restarts per hour)
    if [[ ${RESTART_COUNTS[$name]} -gt 5 ]]; then
        log "❌ $name exceeded restart limit (${RESTART_COUNTS[$name]}), disabling"
        return 1
    fi

    # Kill existing process if it's still running
    if [[ -n "${PROCESS_PIDS[$name]:-}" ]]; then
        kill "${PROCESS_PIDS[$name]}" 2>/dev/null || true
        sleep 2
    fi

    log "🔄 Restarting $name (attempt ${RESTART_COUNTS[$name]})"
    start_process "$name" "$command"

    # Exponential backoff delay
    local delay=$((2 ** ${RESTART_COUNTS[$name]}))
    log "⏳ Waiting ${delay}s before next health check"
    sleep "$delay"
}

# Initialize all processes
for name in "${!PROCESSES[@]}"; do
    command="${PROCESSES[$name]}"

    # Check if command is available
    if ! command -v "${command%% *}" >/dev/null 2>&1; then
        log "⚠️ Command not found for $name: ${command%% *}, skipping"
        unset PROCESSES[$name]
        continue
    fi

    start_process "$name" "$command"
done

# Main monitoring loop
log "👀 Starting health monitoring loop"

while true; do
    for name in "${!PROCESSES[@]}"; do
        command="${PROCESSES[$name]}"

        if ! check_process_health "$name" "$command"; then
            log "💔 $name is not healthy, attempting restart"

            if ! restart_process "$name" "$command"; then
                log "🚫 Removing $name from monitoring due to restart failures"
                unset PROCESSES[$name]
                unset PROCESS_PIDS[$name]
                unset RESTART_COUNTS[$name]
            fi
        fi
    done

    # Reset restart counts every hour
    if [[ $(date +%M) == "00" ]]; then
        for name in "${!RESTART_COUNTS[@]}"; do
            RESTART_COUNTS[$name]=0
        done
        log "🔄 Reset restart counts for new hour"
    fi

    # Check every 30 seconds
    sleep 30
done