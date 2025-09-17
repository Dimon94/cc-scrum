#!/bin/bash

# CC-Scrum User Prompt Submit Hook
# Analyzes user prompts and provides intelligent routing to appropriate agents

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PROMPT-HOOK] $*" | tee -a "$LOG_FILE"
}

# User prompt context
USER_PROMPT="${CLAUDE_USER_PROMPT:-}"
CONVERSATION_HISTORY="${CLAUDE_CONVERSATION_HISTORY:-}"
SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%s)}"

log "💬 Analyzing user prompt (session: $SESSION_ID)"

# Check if settings exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
    log "⚠️ Settings file not found, using defaults"
    exit 0
fi

# Smart agent routing
SMART_CONTEXT=$(jq -r '.automation.smart_context // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$SMART_CONTEXT" == "true" ]] && [[ -n "$USER_PROMPT" ]]; then
    log "🧠 Smart context analysis enabled"

    # Analyze prompt for agent suggestions
    SUGGESTED_AGENTS=()

    # Product Owner keywords
    if echo "$USER_PROMPT" | grep -iE "(user story|requirement|feature|epic|acceptance criteria|product|customer|business)" >/dev/null; then
        SUGGESTED_AGENTS+=("@po")
    fi

    # Scrum Master keywords
    if echo "$USER_PROMPT" | grep -iE "(sprint|standup|retrospective|velocity|burndown|impediment|ceremony|process)" >/dev/null; then
        SUGGESTED_AGENTS+=("@sm")
    fi

    # Architect keywords
    if echo "$USER_PROMPT" | grep -iE "(architecture|design|pattern|framework|scalability|performance|system|adr|decision)" >/dev/null; then
        SUGGESTED_AGENTS+=("@arch")
    fi

    # Developer keywords
    if echo "$USER_PROMPT" | grep -iE "(code|implement|function|class|algorithm|debug|refactor|api|database)" >/dev/null; then
        SUGGESTED_AGENTS+=("@dev")
    fi

    # QA keywords
    if echo "$USER_PROMPT" | grep -iE "(test|quality|bug|coverage|automation|validation|edge case|regression)" >/dev/null; then
        SUGGESTED_AGENTS+=("@qa")
    fi

    # Security keywords
    if echo "$USER_PROMPT" | grep -iE "(security|vulnerability|auth|encryption|owasp|threat|compliance|audit)" >/dev/null; then
        SUGGESTED_AGENTS+=("@sec")
    fi

    # Meta-Todo keywords
    if echo "$USER_PROMPT" | grep -iE "(break down|tasks|todo|plan|organize|complex|multi-step)" >/dev/null; then
        echo "💡 Meta-Todo Suggestion: This request might benefit from /meta-todo command for intelligent task breakdown"
    fi

    # Review keywords
    if echo "$USER_PROMPT" | grep -iE "(review|check|validate|approve|merge|ready)" >/dev/null; then
        echo "💡 Review Suggestion: Consider using /review command for comprehensive code review"
    fi

    # Standup keywords
    if echo "$USER_PROMPT" | grep -iE "(progress|yesterday|today|blockers|status|update)" >/dev/null; then
        echo "💡 Standup Suggestion: Use /standup command for structured daily standup reporting"
    fi

    # Output agent suggestions
    if [[ ${#SUGGESTED_AGENTS[@]} -gt 0 ]]; then
        UNIQUE_AGENTS=($(printf "%s\n" "${SUGGESTED_AGENTS[@]}" | sort -u))
        log "🎯 Suggested agents: ${UNIQUE_AGENTS[*]}"
        echo "💡 Agent Suggestions: ${UNIQUE_AGENTS[*]} might be helpful for this request"
    fi

    # Check for missing context
    if echo "$USER_PROMPT" | grep -iE "(this|that|it|the file|the function)" >/dev/null && [[ -z "$CONVERSATION_HISTORY" ]]; then
        echo "⚠️ Context Alert: Your request references 'this/that/it' but context might be missing"
    fi
fi

# Scrum workflow analysis
SCRUM_ENABLED=$(jq -r '.scrum.enabled // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")

if [[ "$SCRUM_ENABLED" == "true" ]]; then
    SPRINT_FILE="$PROJECT_ROOT/.claude/data/current_sprint.json"

    # Check sprint context
    if [[ -f "$SPRINT_FILE" ]]; then
        SPRINT_STATUS=$(jq -r '.status // "unknown"' "$SPRINT_FILE" 2>/dev/null || echo "unknown")
        SPRINT_GOAL=$(jq -r '.goal // ""' "$SPRINT_FILE" 2>/dev/null || echo "")

        case "$SPRINT_STATUS" in
            "planning")
                if echo "$USER_PROMPT" | grep -iE "(story|epic|estimate|priority)" >/dev/null; then
                    echo "🎯 Sprint Planning: Your request aligns with current sprint planning activities"
                fi
                ;;
            "active")
                if echo "$USER_PROMPT" | grep -iE "(deploy|release|production)" >/dev/null; then
                    echo "⚠️ Sprint Active: Consider sprint review process for production changes"
                fi
                ;;
            "review")
                if echo "$USER_PROMPT" | grep -iE "(retrospective|feedback|improvement)" >/dev/null; then
                    echo "🔍 Sprint Review: Perfect timing for retrospective activities"
                fi
                ;;
        esac

        # Check alignment with sprint goal
        if [[ -n "$SPRINT_GOAL" ]] && echo "$USER_PROMPT" | grep -iE "$(echo "$SPRINT_GOAL" | tr '[:upper:]' '[:lower:]')" >/dev/null; then
            echo "🎯 Sprint Alignment: Your request supports the current sprint goal"
        fi
    fi

    # Track user engagement patterns
    ENGAGEMENT_FILE="$PROJECT_ROOT/.claude/data/user_engagement.json"
    mkdir -p "$(dirname "$ENGAGEMENT_FILE")"

    ENGAGEMENT_ENTRY="{
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"session_id\": \"$SESSION_ID\",
        \"prompt_length\": ${#USER_PROMPT},
        \"prompt_type\": \"$(echo "$USER_PROMPT" | head -c 50 | tr '\n' ' ')...\",
        \"suggested_agents\": [$(printf '"%s",' "${SUGGESTED_AGENTS[@]}" | sed 's/,$//')],
        \"context_available\": $([ -n "$CONVERSATION_HISTORY" ] && echo "true" || echo "false")
    }"

    if [[ -f "$ENGAGEMENT_FILE" ]]; then
        jq ". += [$ENGAGEMENT_ENTRY] | if length > 500 then .[1:] else . end" "$ENGAGEMENT_FILE" > "${ENGAGEMENT_FILE}.tmp" && mv "${ENGAGEMENT_FILE}.tmp" "$ENGAGEMENT_FILE"
    else
        echo "[$ENGAGEMENT_ENTRY]" > "$ENGAGEMENT_FILE"
    fi
fi

# Quality hints based on prompt analysis
PROMPT_LENGTH=${#USER_PROMPT}

if [[ $PROMPT_LENGTH -lt 10 ]]; then
    echo "💡 Communication Tip: More detailed requests often lead to better results"
elif [[ $PROMPT_LENGTH -gt 1000 ]]; then
    echo "💡 Communication Tip: Consider breaking complex requests into smaller parts"
fi

# Check for common anti-patterns
if echo "$USER_PROMPT" | grep -iE "(please|thank you|sorry)" >/dev/null; then
    log "😊 Polite user interaction detected"
fi

if echo "$USER_PROMPT" | grep -iE "(fix|broken|error|problem)" >/dev/null && ! echo "$USER_PROMPT" | grep -iE "(specific|exact|details|reproduce)" >/dev/null; then
    echo "💡 Debugging Tip: Specific error messages and reproduction steps help diagnose issues faster"
fi

# Project-specific context awareness
if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    PROJECT_TYPE="nodejs"
elif [[ -f "$PROJECT_ROOT/requirements.txt" ]] || [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
    PROJECT_TYPE="python"
elif [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
    PROJECT_TYPE="rust"
elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
    PROJECT_TYPE="go"
else
    PROJECT_TYPE="unknown"
fi

if [[ "$PROJECT_TYPE" != "unknown" ]] && echo "$USER_PROMPT" | grep -iE "(build|test|deploy|run)" >/dev/null; then
    echo "💡 Project Context: $PROJECT_TYPE project detected - standard commands available"
fi

# Emergency keywords detection
if echo "$USER_PROMPT" | grep -iE "(urgent|emergency|critical|production down|outage)" >/dev/null; then
    log "🚨 URGENT REQUEST DETECTED"
    echo "🚨 Urgent Request: Prioritizing immediate assistance"

    # Skip normal processing delays for urgent requests
    export CLAUDE_URGENT_MODE=true
fi

log "✅ Prompt analysis completed"
exit 0