#!/bin/bash

# CC-Scrum Template Generator
# Generates project-specific documentation from templates

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$CLAUDE_DIR/templates"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/../.." && pwd)"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEMPLATE-GEN] $*"
}

# Check if templates directory exists
if [[ ! -d "$TEMPLATES_DIR" ]]; then
    log "ERROR: Templates directory not found at $TEMPLATES_DIR"
    exit 1
fi

# Check if settings file exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
    log "ERROR: Settings file not found at $SETTINGS_FILE"
    exit 1
fi

# Parse settings
PROJECT_NAME=$(jq -r '.project.name // "unknown"' "$SETTINGS_FILE")
PROJECT_TYPE=$(jq -r '.project.type // "generic"' "$SETTINGS_FILE")
PROJECT_DESCRIPTION=$(jq -r '.project.description // ""' "$SETTINGS_FILE")
SPRINT_DURATION=$(jq -r '.scrum.sprint_duration_weeks // 2' "$SETTINGS_FILE")
COVERAGE_THRESHOLD=$(jq -r '.scrum.quality_gates.code_coverage_threshold // 80' "$SETTINGS_FILE")
SECURITY_ENABLED=$(jq -r '.scrum.quality_gates.security_scan_required // false' "$SETTINGS_FILE")
BACKGROUND_MONITORING=$(jq -r '.scrum.automation.background_processes // false' "$SETTINGS_FILE")
ENABLED_AGENTS=$(jq -r '.agents.enabled[]' "$SETTINGS_FILE" | tr '\n' ',' | sed 's/,$//')

# Template variables
FRAMEWORK_VERSION="1.0.0"
GENERATION_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date '+%Y-%m-%d')
SPRINT_START_DATE="$TODAY"
SPRINT_END_DATE=$(date -d "+$SPRINT_DURATION weeks" '+%Y-%m-%d')
TODAY_PLUS_1=$(date -d "+1 day" '+%Y-%m-%d')
SECURITY_STATUS=$([ "$SECURITY_ENABLED" = "true" ] && echo "Enabled" || echo "Disabled")

log "Generating documentation for $PROJECT_NAME ($PROJECT_TYPE)"

# Simple template processor function
process_template() {
    local template_file="$1"
    local output_file="$2"

    if [[ ! -f "$template_file" ]]; then
        log "WARNING: Template $template_file not found"
        return 1
    fi

    log "Processing template: $(basename "$template_file") -> $(basename "$output_file")"

    # Start with the template content
    local content
    content=$(cat "$template_file")

    # Replace basic variables
    content=${content//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}
    content=${content//\{\{PROJECT_TYPE\}\}/$PROJECT_TYPE}
    content=${content//\{\{PROJECT_DESCRIPTION\}\}/$PROJECT_DESCRIPTION}
    content=${content//\{\{SPRINT_DURATION\}\}/$SPRINT_DURATION}
    content=${content//\{\{COVERAGE_THRESHOLD\}\}/$COVERAGE_THRESHOLD}
    content=${content//\{\{ENABLED_AGENTS\}\}/$ENABLED_AGENTS}
    content=${content//\{\{FRAMEWORK_VERSION\}\}/$FRAMEWORK_VERSION}
    content=${content//\{\{GENERATION_DATE\}\}/$GENERATION_DATE}
    content=${content//\{\{TODAY\}\}/$TODAY}
    content=${content//\{\{SPRINT_START_DATE\}\}/$SPRINT_START_DATE}
    content=${content//\{\{SPRINT_END_DATE\}\}/$SPRINT_END_DATE}
    content=${content//\{\{TODAY_PLUS_1\}\}/$TODAY_PLUS_1}
    content=${content//\{\{SECURITY_STATUS\}\}/$SECURITY_STATUS}

    # Process conditional blocks
    # Handle project type conditionals
    if [[ "$PROJECT_TYPE" == "nodejs" ]]; then
        content=$(echo "$content" | sed '/{{#if_nodejs}}/,/{{\/if_nodejs}}/{ s/{{#if_nodejs}}//; s/{{\/if_nodejs}}//; }')
    else
        content=$(echo "$content" | sed '/{{#if_nodejs}}/,/{{\/if_nodejs}}/d')
    fi

    if [[ "$PROJECT_TYPE" == "python" ]]; then
        content=$(echo "$content" | sed '/{{#if_python}}/,/{{\/if_python}}/{ s/{{#if_python}}//; s/{{\/if_python}}//; }')
    else
        content=$(echo "$content" | sed '/{{#if_python}}/,/{{\/if_python}}/d')
    fi

    if [[ "$PROJECT_TYPE" == "rust" ]]; then
        content=$(echo "$content" | sed '/{{#if_rust}}/,/{{\/if_rust}}/{ s/{{#if_rust}}//; s/{{\/if_rust}}//; }')
    else
        content=$(echo "$content" | sed '/{{#if_rust}}/,/{{\/if_rust}}/d')
    fi

    if [[ "$PROJECT_TYPE" == "go" ]]; then
        content=$(echo "$content" | sed '/{{#if_go}}/,/{{\/if_go}}/{ s/{{#if_go}}//; s/{{\/if_go}}//; }')
    else
        content=$(echo "$content" | sed '/{{#if_go}}/,/{{\/if_go}}/d')
    fi

    # Handle security conditionals
    if [[ "$SECURITY_ENABLED" == "true" ]]; then
        content=$(echo "$content" | sed '/{{#if_security_enabled}}/,/{{\/if_security_enabled}}/{ s/{{#if_security_enabled}}//; s/{{\/if_security_enabled}}//; }')
    else
        content=$(echo "$content" | sed '/{{#if_security_enabled}}/,/{{\/if_security_enabled}}/d')
    fi

    # Handle background monitoring conditionals
    if [[ "$BACKGROUND_MONITORING" == "true" ]]; then
        content=$(echo "$content" | sed '/{{#if_background_monitoring}}/,/{{\/if_background_monitoring}}/{ s/{{#if_background_monitoring}}//; s/{{\/if_background_monitoring}}//; }')
    else
        content=$(echo "$content" | sed '/{{#if_background_monitoring}}/,/{{\/if_background_monitoring}}/d')
    fi

    # Write the processed content
    echo "$content" > "$output_file"

    log "Generated: $output_file"
}

# Generate BACKLOG.md
if [[ -f "$TEMPLATES_DIR/backlog.template" ]]; then
    process_template "$TEMPLATES_DIR/backlog.template" "$PROJECT_ROOT/BACKLOG.md"
else
    log "WARNING: backlog.template not found, skipping BACKLOG.md generation"
fi

# Generate DOD.md
if [[ -f "$TEMPLATES_DIR/dod.template" ]]; then
    process_template "$TEMPLATES_DIR/dod.template" "$PROJECT_ROOT/DOD.md"
else
    log "WARNING: dod.template not found, skipping DOD.md generation"
fi

# Generate SPRINT.md
if [[ -f "$TEMPLATES_DIR/sprint.template" ]]; then
    process_template "$TEMPLATES_DIR/sprint.template" "$PROJECT_ROOT/SPRINT.md"
else
    log "WARNING: sprint.template not found, skipping SPRINT.md generation"
fi

# Update current sprint data
SPRINT_DATA_FILE="$CLAUDE_DIR/data/current_sprint.json"
if [[ -f "$SPRINT_DATA_FILE" ]]; then
    log "Updating sprint data file"

    # Update sprint data with template generation activity
    jq ".activities += [{
        \"timestamp\": \"$GENERATION_DATE\",
        \"type\": \"documentation_update\",
        \"description\": \"Project documentation regenerated from templates\"
    }] | .last_updated = \"$GENERATION_DATE\"" "$SPRINT_DATA_FILE" > "${SPRINT_DATA_FILE}.tmp" && mv "${SPRINT_DATA_FILE}.tmp" "$SPRINT_DATA_FILE"
fi

log "Template generation completed successfully"
log "Generated files: BACKLOG.md, DOD.md, SPRINT.md"
log "All files are customized for $PROJECT_TYPE project: $PROJECT_NAME"