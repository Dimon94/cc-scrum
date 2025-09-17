#!/bin/bash

# CC-Scrum Post-Tool Use Hook
# Analyzes tool results and triggers follow-up actions

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.claude/logs/hooks.log"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [POST-HOOK] $*" | tee -a "$LOG_FILE"
}

# Tool execution context
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_ARGS="${CLAUDE_TOOL_ARGS:-{}}"
TOOL_RESULT="${CLAUDE_TOOL_RESULT:-}"
TOOL_SUCCESS="${CLAUDE_TOOL_SUCCESS:-true}"
EXECUTION_TIME="${CLAUDE_EXECUTION_TIME:-0}"

log "📊 Post-tool analysis for: $TOOL_NAME (success: $TOOL_SUCCESS, time: ${EXECUTION_TIME}ms)"

# Check if settings exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
    log "⚠️ Settings file not found, using defaults"
    exit 0
fi

# Auto-healing for failed tools
if [[ "$TOOL_SUCCESS" == "false" ]]; then
    AUTO_HEALING=$(jq -r '.automation.auto_healing // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

    if [[ "$AUTO_HEALING" == "true" ]]; then
        log "🔧 Auto-healing triggered for failed tool: $TOOL_NAME"

        case "$TOOL_NAME" in
            "Bash")
                COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command // ""' 2>/dev/null || echo "")

                # Common failure patterns and solutions
                if echo "$TOOL_RESULT" | grep -q "command not found"; then
                    MISSING_CMD=$(echo "$TOOL_RESULT" | grep -o "[^:]*: command not found" | cut -d: -f1)
                    log "💡 Suggesting installation for missing command: $MISSING_CMD"
                    echo "Auto-heal suggestion: Install $MISSING_CMD or check PATH"

                elif echo "$TOOL_RESULT" | grep -q "Permission denied"; then
                    log "💡 Permission issue detected, suggesting chmod"
                    echo "Auto-heal suggestion: Check file permissions or run with appropriate privileges"

                elif echo "$TOOL_RESULT" | grep -q "No such file or directory"; then
                    log "💡 File not found, checking common locations"
                    echo "Auto-heal suggestion: Verify file path or create missing directories"
                fi
                ;;

            "Read")
                FILE_PATH=$(echo "$TOOL_ARGS" | jq -r '.file_path // ""' 2>/dev/null || echo "")
                if [[ -n "$FILE_PATH" ]] && echo "$TOOL_RESULT" | grep -q "not found\|does not exist"; then
                    log "💡 Missing file detected: $FILE_PATH"
                    echo "Auto-heal suggestion: Create $FILE_PATH or check path spelling"
                fi
                ;;

            "Edit"|"Write")
                if echo "$TOOL_RESULT" | grep -q "Permission denied"; then
                    log "💡 Write permission issue detected"
                    echo "Auto-heal suggestion: Check file write permissions"
                fi
                ;;
        esac
    fi
fi

# Quality gate triggers
if [[ "$TOOL_SUCCESS" == "true" ]] && [[ "$TOOL_NAME" =~ ^(Edit|Write|MultiEdit)$ ]]; then
    FILE_PATH=$(echo "$TOOL_ARGS" | jq -r '.file_path // ""' 2>/dev/null || echo "")

    # Auto-trigger quality checks for code modifications
    if [[ "$FILE_PATH" =~ \.(js|ts|jsx|tsx|py|go|java|c|cpp|h|hpp)$ ]]; then
        QUALITY_GATES=$(jq -r '.scrum.quality_gates // {}' "$SETTINGS_FILE" 2>/dev/null || echo "{}")

        log "🎯 Code modification detected, scheduling quality checks"

        # Schedule background quality checks
        QUALITY_SCRIPT="$PROJECT_ROOT/.claude/scripts/quality-gate-check.sh"
        if [[ -f "$QUALITY_SCRIPT" ]]; then
            log "🚀 Triggering background quality gate check"
            nohup "$QUALITY_SCRIPT" --quiet > "$PROJECT_ROOT/.claude/logs/auto_quality_check.log" 2>&1 &
            echo "Background quality check scheduled for $FILE_PATH"
        fi
    fi

    # Documentation updates
    if [[ "$FILE_PATH" =~ \.(md|txt|rst)$ ]]; then
        log "📝 Documentation update detected: $FILE_PATH"

        # Check if it's a major documentation file
        if [[ "$FILE_PATH" =~ (README|CHANGELOG|ARCHITECTURE|API)\.md$ ]]; then
            log "📚 Major documentation update - triggering review workflow"
            echo "Major documentation change detected - consider team review"
        fi
    fi
fi

# Agent collaboration tracking
SMART_CONTEXT=$(jq -r '.automation.smart_context // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$SMART_CONTEXT" == "true" ]]; then
    # Track tool usage patterns for intelligent suggestions
    CONTEXT_FILE="$PROJECT_ROOT/.claude/data/tool_context.json"
    mkdir -p "$(dirname "$CONTEXT_FILE")"

    # Update context with tool usage
    CONTEXT_ENTRY="{
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"tool\": \"$TOOL_NAME\",
        \"success\": $TOOL_SUCCESS,
        \"execution_time\": $EXECUTION_TIME,
        \"file_pattern\": \"$(echo "$TOOL_ARGS" | jq -r '.file_path // ""' | sed 's/[^.]*\(\.[^.]*\)$/\1/' 2>/dev/null || echo "")\",
        \"context_hash\": \"$(echo "$TOOL_ARGS" | sha256sum | cut -d' ' -f1)\"
    }"

    # Append to context file (keeping last 1000 entries)
    if [[ -f "$CONTEXT_FILE" ]]; then
        jq ". += [$CONTEXT_ENTRY] | if length > 1000 then .[1:] else . end" "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp" && mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
    else
        echo "[$CONTEXT_ENTRY]" > "$CONTEXT_FILE"
    fi

    # Analyze patterns and suggest optimizations
    USAGE_COUNT=$(jq "[.[] | select(.tool == \"$TOOL_NAME\" and .success == true)] | length" "$CONTEXT_FILE" 2>/dev/null || echo "0")

    if [[ $USAGE_COUNT -gt 5 ]]; then
        AVG_TIME=$(jq "[.[] | select(.tool == \"$TOOL_NAME\" and .success == true) | .execution_time] | add / length" "$CONTEXT_FILE" 2>/dev/null || echo "0")

        if [[ $(echo "$EXECUTION_TIME > $AVG_TIME * 2" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
            log "⚠️ Performance anomaly: $TOOL_NAME took ${EXECUTION_TIME}ms (avg: ${AVG_TIME}ms)"
            echo "Performance notice: $TOOL_NAME execution was slower than usual"
        fi
    fi
fi

# Sprint progress tracking
SCRUM_ENABLED=$(jq -r '.scrum.enabled // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$SCRUM_ENABLED" == "true" ]] && [[ "$TOOL_SUCCESS" == "true" ]]; then
    SPRINT_FILE="$PROJECT_ROOT/.claude/data/current_sprint.json"

    if [[ -f "$SPRINT_FILE" ]]; then
        # Update sprint activity
        ACTIVITY_ENTRY="{
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
            \"tool\": \"$TOOL_NAME\",
            \"type\": \"tool_usage\",
            \"execution_time\": $EXECUTION_TIME
        }"

        # Add to sprint activities
        jq ".activities += [$ACTIVITY_ENTRY] | .last_updated = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$SPRINT_FILE" > "${SPRINT_FILE}.tmp" && mv "${SPRINT_FILE}.tmp" "$SPRINT_FILE"

        log "📈 Sprint activity updated with tool usage"
    fi
fi

# Background process health check
MONITOR_ENABLED=$(jq -r '.background_monitoring.auto_restart // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$MONITOR_ENABLED" == "true" ]] && [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command // ""' 2>/dev/null || echo "")

    # Check if this was a build/dev command that might affect running processes
    if [[ "$COMMAND" =~ (npm|yarn|build|install|update) ]]; then
        log "🔄 Build command detected, checking background processes"

        MONITOR_SCRIPT="$PROJECT_ROOT/.claude/scripts/background-monitor.sh"
        if [[ -f "$MONITOR_SCRIPT" ]]; then
            # Check if monitor is running
            PID_FILE="$PROJECT_ROOT/.claude/pids/monitor.pid"
            if [[ ! -f "$PID_FILE" ]] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
                log "🚀 Restarting background monitor"
                nohup "$MONITOR_SCRIPT" > "$PROJECT_ROOT/.claude/logs/monitor_restart.log" 2>&1 &
                echo "Background monitor restarted after build command"
            fi
        fi
    fi
fi

# Performance and usage analytics
ANALYTICS_FILE="$PROJECT_ROOT/.claude/logs/tool_analytics.jsonl"
echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tool\":\"$TOOL_NAME\",\"success\":$TOOL_SUCCESS,\"execution_time\":$EXECUTION_TIME,\"result_size\":${#TOOL_RESULT}}" >> "$ANALYTICS_FILE"

log "✅ Post-tool analysis completed for: $TOOL_NAME"
exit 0