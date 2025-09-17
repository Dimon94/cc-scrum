#!/bin/bash

# CC-Scrum Pre-Tool Use Hook
# Validates tool usage context and enforces quality gates

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PRE-HOOK] $*" | tee -a "$LOG_FILE"
}

# Tool usage context
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TOOL_ARGS="${CLAUDE_TOOL_ARGS:-{}}"
USER_MESSAGE="${CLAUDE_USER_MESSAGE:-}"
CONVERSATION_CONTEXT="${CLAUDE_CONVERSATION_CONTEXT:-}"

log "🔍 Pre-tool validation for: $TOOL_NAME"

# Check if settings exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
    log "⚠️ Settings file not found, using defaults"
    exit 0
fi

# Parse settings
DANGEROUS_COMMANDS=$(jq -r '.security.dangerous_commands[]?' "$SETTINGS_FILE" 2>/dev/null || echo "")
REQUIRE_CONFIRMATION=$(jq -r '.security.require_confirmation[]?' "$SETTINGS_FILE" 2>/dev/null || echo "")

# Security validation for Bash tool
if [[ "$TOOL_NAME" == "Bash" ]]; then
    # Extract command from args
    COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command // ""' 2>/dev/null || echo "")

    # Check for dangerous commands
    while IFS= read -r dangerous_cmd; do
        if [[ -n "$dangerous_cmd" && "$COMMAND" == *"$dangerous_cmd"* ]]; then
            log "🚫 BLOCKED: Dangerous command detected: $dangerous_cmd"
            echo "Security policy violation: Command '$dangerous_cmd' is not allowed"
            exit 1
        fi
    done <<< "$DANGEROUS_COMMANDS"

    # Check for commands requiring confirmation
    while IFS= read -r confirm_cmd; do
        if [[ -n "$confirm_cmd" && "$COMMAND" == *"$confirm_cmd"* ]]; then
            log "⚠️ WARNING: Command requires confirmation: $confirm_cmd"
            echo "Warning: Command '$confirm_cmd' requires manual confirmation"
            # Note: In real implementation, this would prompt user
        fi
    done <<< "$REQUIRE_CONFIRMATION"
fi

# Quality gate validation for Edit/Write tools
if [[ "$TOOL_NAME" =~ ^(Edit|Write|MultiEdit)$ ]]; then
    FILE_PATH=$(echo "$TOOL_ARGS" | jq -r '.file_path // ""' 2>/dev/null || echo "")

    # Check if modifying critical files
    if [[ "$FILE_PATH" =~ \.(json|yaml|yml|config|env)$ ]]; then
        log "📝 Modifying configuration file: $FILE_PATH"

        # Validate JSON/YAML syntax if applicable
        if [[ "$FILE_PATH" =~ \.json$ ]] && [[ -f "$FILE_PATH" ]]; then
            if ! jq . "$FILE_PATH" >/dev/null 2>&1; then
                log "❌ BLOCKED: Invalid JSON in target file"
                echo "Error: Target file contains invalid JSON"
                exit 1
            fi
        fi
    fi

    # Check for Documentation of Done (DoD) compliance
    if [[ "$FILE_PATH" =~ \.(js|ts|jsx|tsx|py|go|java|c|cpp|h|hpp)$ ]]; then
        log "🔍 Code modification detected, checking DoD compliance"

        # Check if tests exist for the modified file
        TEST_PATTERNS=(
            "${FILE_PATH%.*}.test.*"
            "${FILE_PATH%.*}.spec.*"
            "tests/**/*${FILE_PATH##*/}*"
            "test/**/*${FILE_PATH##*/}*"
        )

        TEST_EXISTS=false
        for pattern in "${TEST_PATTERNS[@]}"; do
            if compgen -G "$pattern" > /dev/null 2>&1; then
                TEST_EXISTS=true
                break
            fi
        done

        if [[ "$TEST_EXISTS" == "false" ]]; then
            log "⚠️ WARNING: No tests found for $FILE_PATH"
            echo "DoD Warning: Consider adding tests for this file"
        fi
    fi
fi

# Context-aware validation
SCRUM_ENABLED=$(jq -r '.scrum.enabled // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$SCRUM_ENABLED" == "true" ]]; then
    # Check if we're in a sprint
    SPRINT_FILE="$PROJECT_ROOT/.claude/data/current_sprint.json"
    if [[ -f "$SPRINT_FILE" ]]; then
        SPRINT_STATUS=$(jq -r '.status // "unknown"' "$SPRINT_FILE" 2>/dev/null || echo "unknown")

        if [[ "$SPRINT_STATUS" == "active" ]]; then
            log "🏃 Active sprint detected - enforcing stricter quality gates"

            # Block direct production deployments during sprint
            if [[ "$TOOL_NAME" == "Bash" ]] && [[ "$COMMAND" == *"deploy"* || "$COMMAND" == *"release"* ]]; then
                log "🚫 BLOCKED: Direct deployment not allowed during active sprint"
                echo "Sprint Policy: Deployments must go through sprint review process"
                exit 1
            fi
        fi
    fi
fi

# Agent collaboration context
if [[ -n "$CONVERSATION_CONTEXT" ]] && echo "$CONVERSATION_CONTEXT" | grep -q "@[a-z]\+"; then
    # Extract mentioned agents
    MENTIONED_AGENTS=$(echo "$CONVERSATION_CONTEXT" | grep -o "@[a-z]\+" | sort -u)
    log "👥 Agent collaboration detected: $MENTIONED_AGENTS"

    # Check if agents are properly configured
    while IFS= read -r agent; do
        AGENT_NAME="${agent#@}"
        AGENT_FILE="$PROJECT_ROOT/.claude/agents/${AGENT_NAME}.md"

        if [[ ! -f "$AGENT_FILE" ]]; then
            log "⚠️ WARNING: Referenced agent not found: $AGENT_NAME"
            echo "Warning: Agent @$AGENT_NAME is not configured"
        fi
    done <<< "$MENTIONED_AGENTS"
fi

# Performance monitoring
MONITOR_ENABLED=$(jq -r '.background_monitoring.log_analysis // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$MONITOR_ENABLED" == "true" ]]; then
    # Log tool usage for analysis
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tool\":\"$TOOL_NAME\",\"args_hash\":\"$(echo "$TOOL_ARGS" | sha256sum | cut -d' ' -f1)\",\"context\":\"pre_validation\"}" >> "$PROJECT_ROOT/.claude/logs/tool_usage.jsonl"
fi

log "✅ Pre-tool validation completed for: $TOOL_NAME"
exit 0