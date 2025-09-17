#!/bin/bash

# CC-Scrum Framework Universal Installer
# Cross-platform installer for macOS, Linux, and Windows (WSL)

set -euo pipefail

# Version and metadata
INSTALLER_VERSION="1.1.0"
FRAMEWORK_VERSION="1.0.0"

# Colors for output (with fallback for systems without color support)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    NC=$(tput sgr0)
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# Platform detection
PLATFORM=""
OS_NAME=""
BASH_VERSION=""

# Date command compatibility
DATE_CMD=""
DATE_ADD_WEEKS=""
DATE_ADD_DAYS=""

# Configuration
# Handle BASH_SOURCE[0] being unbound when script is piped (curl | bash)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback: assume script is in current directory or use a reasonable default
    SCRIPT_DIR="$(pwd)"
    echo "⚠️ Script executed via pipe - using current directory as SCRIPT_DIR"
fi
FRAMEWORK_DIR="$SCRIPT_DIR/.claude"
TARGET_DIR="$(pwd)"
INSTALL_LOG="$TARGET_DIR/cc-scrum-install.log"

# Project detection
PROJECT_TYPE=""
PROJECT_NAME=""
PROJECT_DESCRIPTION=""

# Installation options
UNATTENDED_MODE=false
DRY_RUN_MODE=false
VERBOSE_MODE=false

# Detect if script is being piped (stdin is not a terminal)
if [[ ! -t 0 ]]; then
    UNATTENDED_MODE=true
    echo "⚠️ Pipe execution detected - enabling unattended mode"
fi

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$INSTALL_LOG"
}

# Print colored output with fallback
print_step() {
    echo -e "${CYAN}🔧 $*${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $*${NC}"
}

print_error() {
    echo -e "${RED}❌ $*${NC}"
}

print_info() {
    echo -e "${BLUE}💡 $*${NC}"
}

# Platform detection function
detect_platform() {
    print_step "Detecting platform..."

    # Detect OS
    case "$(uname -s)" in
        Darwin*)
            PLATFORM="macOS"
            OS_NAME="macOS $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
            ;;
        Linux*)
            if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
                PLATFORM="WSL"
                OS_NAME="Windows Subsystem for Linux"
            else
                PLATFORM="Linux"
                if command -v lsb_release >/dev/null 2>&1; then
                    OS_NAME="$(lsb_release -d -s 2>/dev/null || echo 'Linux')"
                elif [[ -f /etc/os-release ]]; then
                    OS_NAME="$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
                else
                    OS_NAME="Linux"
                fi
            fi
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            PLATFORM="Windows"
            OS_NAME="Windows (Git Bash/MSYS2)"
            ;;
        *)
            PLATFORM="Unknown"
            OS_NAME="Unknown OS"
            print_warning "Unknown platform detected, using generic settings"
            ;;
    esac

    # Detect Bash version
    BASH_VERSION="${BASH_VERSION:-${BASH_VERSINFO[0]:-3}.${BASH_VERSINFO[1]:-2}}"
    BASH_MAJOR_VERSION=$(echo "$BASH_VERSION" | cut -d. -f1)

    print_info "Platform: $PLATFORM"
    print_info "OS: $OS_NAME"
    print_info "Bash: $BASH_VERSION"

    # Configure date commands based on platform
    configure_date_commands

    print_success "Platform detection completed"
}

# Configure date commands for cross-platform compatibility
configure_date_commands() {
    case "$PLATFORM" in
        "macOS")
            # macOS uses BSD date
            DATE_CMD="date"
            DATE_ADD_WEEKS="date -v +%dw"
            DATE_ADD_DAYS="date -v +%dd"
            ;;
        "Linux"|"WSL")
            # Linux uses GNU date
            DATE_CMD="date"
            DATE_ADD_WEEKS="date -d '+%d weeks'"
            DATE_ADD_DAYS="date -d '+%d days'"
            ;;
        "Windows")
            # Windows Git Bash usually has GNU date
            DATE_CMD="date"
            DATE_ADD_WEEKS="date -d '+%d weeks'"
            DATE_ADD_DAYS="date -d '+%d days'"
            ;;
        *)
            # Fallback to basic date command
            DATE_CMD="date"
            DATE_ADD_WEEKS="date"
            DATE_ADD_DAYS="date"
            print_warning "Using basic date commands - some features may not work correctly"
            ;;
    esac
}

# Cross-platform date addition
add_weeks_to_date() {
    local weeks="$1"
    local format="${2:-+%Y-%m-%d}"

    case "$PLATFORM" in
        "macOS")
            date -v "+${weeks}w" "$format"
            ;;
        "Linux"|"WSL"|"Windows")
            date -d "+${weeks} weeks" "$format"
            ;;
        *)
            # Fallback - just return current date
            date "$format"
            ;;
    esac
}

add_days_to_date() {
    local days="$1"
    local format="${2:-+%Y-%m-%d}"

    case "$PLATFORM" in
        "macOS")
            date -v "+${days}d" "$format"
            ;;
        "Linux"|"WSL"|"Windows")
            date -d "+${days} days" "$format"
            ;;
        *)
            # Fallback - just return current date
            date "$format"
            ;;
    esac
}

# Check prerequisites with platform-specific considerations
check_prerequisites() {
    print_step "Checking prerequisites..."

    local errors=0

    # Check if we're in a project directory
    if [[ ! -f "package.json" ]] && [[ ! -f "requirements.txt" ]] && [[ ! -f "Cargo.toml" ]] && [[ ! -f "go.mod" ]]; then
        print_warning "No package manager configuration found"
        if [[ "$UNATTENDED_MODE" == "false" ]]; then
            echo "This might not be a project directory. Continue anyway? (y/N)"
            if [[ -t 0 ]]; then
                read -r response
            else
                # Try to read from terminal directly
                if [[ -c /dev/tty ]]; then
                    read -r response < /dev/tty
                else
                    # Default to 'yes' for continuing installation
                    response="y"
                    echo "⚠️ Cannot read user input in pipe mode - defaulting to 'y' (continue)"
                fi
            fi
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi

    # Check Bash version for associative arrays
    if [[ "$BASH_MAJOR_VERSION" -lt 4 ]] && [[ "$BASH_MAJOR_VERSION" != "unknown" ]]; then
        print_warning "Bash version $BASH_VERSION detected. Some features require Bash 4+"
        print_info "On macOS, install with: brew install bash"
        if [[ "$PLATFORM" == "macOS" ]]; then
            print_info "Alternative: Use /usr/local/bin/bash instead of /bin/bash"
        fi
    fi

    # Check for required commands
    local required_commands=("jq")
    local optional_commands=("git" "curl" "wget")

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_error "Required command not found: $cmd"
            case "$PLATFORM" in
                "macOS")
                    print_info "Install with: brew install $cmd"
                    ;;
                "Linux"|"WSL")
                    print_info "Install with: sudo apt-get install $cmd (Ubuntu/Debian)"
                    print_info "Or: sudo yum install $cmd (CentOS/RHEL)"
                    ;;
                "Windows")
                    print_info "Install jq from: https://stedolan.github.io/jq/download/"
                    ;;
            esac
            ((errors++))
        fi
    done

    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_warning "Optional command not found: $cmd"
        fi
    done

    # Check if .claude directory already exists
    if [[ -d "$TARGET_DIR/.claude" ]]; then
        print_warning "CC-Scrum framework already exists in this directory"
        if [[ "$UNATTENDED_MODE" == "false" ]]; then
            echo "Do you want to overwrite it? (y/N)"
            if [[ -t 0 ]]; then
                read -r response
            else
                # Try to read from terminal directly
                if [[ -c /dev/tty ]]; then
                    read -r response < /dev/tty
                else
                    # Default to 'no' in pipe execution
                    response="N"
                    echo "⚠️ Cannot read user input in pipe mode - defaulting to 'N' (no overwrite)"
                fi
            fi
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf "$TARGET_DIR/.claude"
                print_info "Existing framework removed"
            else
                exit 1
            fi
        else
            rm -rf "$TARGET_DIR/.claude"
            print_info "Existing framework removed (unattended mode)"
        fi
    fi

    # Check if source framework exists
    if [[ ! -d "$FRAMEWORK_DIR" ]]; then
        print_error "CC-Scrum framework source not found at $FRAMEWORK_DIR"
        exit 1
    fi

    # Platform-specific file system checks
    case "$PLATFORM" in
        "Windows")
            # Check for case sensitivity issues
            if [[ ! -f "$(echo "$FRAMEWORK_DIR/settings.json" | tr '[:upper:]' '[:lower:]')" ]]; then
                print_warning "Potential case sensitivity issues on Windows"
            fi
            ;;
        "WSL")
            # Check WSL version and Windows path handling
            if command -v wslpath >/dev/null 2>&1; then
                print_info "WSL environment detected with Windows path support"
            fi
            ;;
    esac

    if [[ $errors -gt 0 ]]; then
        print_error "Prerequisites check failed with $errors errors"
        exit 1
    fi

    print_success "Prerequisites check completed"
}

# Banner with platform info
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                      CC-Scrum Framework                      ║
║              Claude Code Intelligent Development             ║
║                   Universal Installer v1.1                  ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo "Platform: $PLATFORM | OS: $OS_NAME"
    echo "Installer: v$INSTALLER_VERSION | Framework: v$FRAMEWORK_VERSION"
    echo ""
}

# Detect project type and gather information
detect_project() {
    print_step "Detecting project configuration..."

    # Detect project type
    if [[ -f "package.json" ]]; then
        PROJECT_TYPE="nodejs"
        if command -v jq >/dev/null 2>&1; then
            PROJECT_NAME=$(jq -r '.name // "unknown"' package.json 2>/dev/null || echo "unknown")
            PROJECT_DESCRIPTION=$(jq -r '.description // ""' package.json 2>/dev/null || echo "")
        else
            PROJECT_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' package.json | cut -d'"' -f4 || echo "unknown")
            PROJECT_DESCRIPTION=""
        fi
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        PROJECT_TYPE="python"
        if [[ -f "pyproject.toml" ]]; then
            PROJECT_NAME=$(grep -E "^name\s*=" pyproject.toml | sed 's/.*=\s*"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
            PROJECT_DESCRIPTION=$(grep -E "^description\s*=" pyproject.toml | sed 's/.*=\s*"\([^"]*\)".*/\1/' 2>/dev/null || echo "")
        else
            PROJECT_NAME=$(basename "$(pwd)")
        fi
    elif [[ -f "Cargo.toml" ]]; then
        PROJECT_TYPE="rust"
        PROJECT_NAME=$(grep -E "^name\s*=" Cargo.toml | sed 's/.*=\s*"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
        PROJECT_DESCRIPTION=$(grep -E "^description\s*=" Cargo.toml | sed 's/.*=\s*"\([^"]*\)".*/\1/' 2>/dev/null || echo "")
    elif [[ -f "go.mod" ]]; then
        PROJECT_TYPE="go"
        PROJECT_NAME=$(grep -E "^module\s+" go.mod | awk '{print $2}' | xargs basename 2>/dev/null || echo "unknown")
    else
        PROJECT_TYPE="generic"
        PROJECT_NAME=$(basename "$(pwd)")
    fi

    if [[ -z "$PROJECT_DESCRIPTION" ]]; then
        PROJECT_DESCRIPTION="A project using CC-Scrum intelligent development framework"
    fi

    print_info "Project Type: $PROJECT_TYPE"
    print_info "Project Name: $PROJECT_NAME"
    print_info "Description: $PROJECT_DESCRIPTION"
}

# Interactive configuration with platform-aware defaults
interactive_config() {
    if [[ "$UNATTENDED_MODE" == "true" ]]; then
        set_default_config
        return
    fi

    print_step "Interactive configuration..."

    echo "=== CC-Scrum Configuration ==="

    # Sprint duration
    echo -n "Sprint duration in weeks (default: 2): "
    read -r sprint_duration
    sprint_duration=${sprint_duration:-2}

    # Quality gates
    echo -n "Code coverage threshold % (default: 80): "
    read -r coverage_threshold
    coverage_threshold=${coverage_threshold:-80}

    # Security scan
    echo -n "Require security scan (y/N): "
    read -r security_scan
    security_scan=${security_scan:-n}

    # Background monitoring
    echo -n "Enable background monitoring (Y/n): "
    read -r background_monitoring
    background_monitoring=${background_monitoring:-y}

    # Agent selection
    echo "Select agents to enable (default: all):"
    echo "Available: po, sm, arch, dev, qa, sec"
    echo -n "Agents (comma-separated, default: all): "
    read -r agents_input
    if [[ -z "$agents_input" ]] || [[ "$agents_input" == "all" ]]; then
        ENABLED_AGENTS=("po" "sm" "arch" "dev" "qa" "sec")
    else
        IFS=',' read -ra ENABLED_AGENTS <<< "$agents_input"
        # Trim whitespace
        for i in "${!ENABLED_AGENTS[@]}"; do
            ENABLED_AGENTS[$i]=$(echo "${ENABLED_AGENTS[$i]}" | xargs)
        done
    fi

    print_success "Configuration completed"
}

# Set default configuration for unattended mode
set_default_config() {
    sprint_duration=2
    coverage_threshold=80
    security_scan="n"
    background_monitoring="y"
    ENABLED_AGENTS=("po" "sm" "arch" "dev" "qa" "sec")

    print_info "Using default configuration (unattended mode)"
}

# Copy framework files with platform-specific handling
copy_framework() {
    print_step "Installing CC-Scrum framework..."

    # Create target directory
    mkdir -p "$TARGET_DIR/.claude"

    # Copy core framework files with platform-aware handling
    case "$PLATFORM" in
        "Windows")
            # Windows may have issues with certain file attributes
            cp -r "$FRAMEWORK_DIR"/* "$TARGET_DIR/.claude/" 2>/dev/null || {
                print_warning "Using alternative copy method for Windows"
                (cd "$FRAMEWORK_DIR" && tar cf - .) | (cd "$TARGET_DIR/.claude" && tar xf -)
            }
            ;;
        *)
            cp -r "$FRAMEWORK_DIR"/* "$TARGET_DIR/.claude/"
            ;;
    esac

    print_success "Framework files copied"
}

# Generate dynamic configuration with cross-platform date handling
generate_config() {
    print_step "Generating project-specific configuration..."

    # Generate settings.json with proper JSON formatting
    cat > "$TARGET_DIR/.claude/settings.json" << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "type": "$PROJECT_TYPE",
    "description": "$PROJECT_DESCRIPTION",
    "platform": "$PLATFORM",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "scrum": {
    "enabled": true,
    "sprint_duration_weeks": $sprint_duration,
    "quality_gates": {
      "code_coverage_threshold": $coverage_threshold,
      "security_scan_required": $([ "$security_scan" = "y" ] && echo "true" || echo "false"),
      "performance_baseline_required": false
    },
    "automation": {
      "background_processes": $([ "$background_monitoring" = "y" ] && echo "true" || echo "false"),
      "auto_healing": true,
      "smart_context": true
    }
  },
  "agents": {
    "enabled": [$(printf '"%s",' "${ENABLED_AGENTS[@]}" | sed 's/,$//')],
    "default_timeout_seconds": 120,
    "parallel_execution": true
  },
  "hooks": {
    "pre_tool_use": true,
    "post_tool_use": true,
    "user_prompt_submit": true
  },
  "background_monitoring": {
    "check_interval_seconds": 5,
    "auto_restart": true,
    "log_analysis": true
  },
  "security": {
    "dangerous_commands": [
      "rm -rf",
      "kubectl delete",
      "docker system prune",
      "npm uninstall --global"
    ],
    "require_confirmation": [
      "git push --force",
      "npm publish",
      "docker push"
    ]
  },
  "platform": {
    "os": "$PLATFORM",
    "bash_version": "$BASH_VERSION",
    "installer_version": "$INSTALLER_VERSION"
  }
}
EOF

    print_success "Configuration generated"
}

# Generate cross-platform template generator
create_universal_template_generator() {
    print_step "Creating universal template generator..."

    cat > "$TARGET_DIR/.claude/scripts/template-generator.sh" << 'EOF'
#!/bin/bash

# CC-Scrum Universal Template Generator
# Cross-platform template generation script

set -euo pipefail

# Platform detection
PLATFORM=""
case "$(uname -s)" in
    Darwin*) PLATFORM="macOS" ;;
    Linux*)
        if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
            PLATFORM="WSL"
        else
            PLATFORM="Linux"
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="Windows" ;;
    *) PLATFORM="Unknown" ;;
esac

# Cross-platform date functions
add_weeks_to_date() {
    local weeks="$1"
    local format="${2:-+%Y-%m-%d}"

    case "$PLATFORM" in
        "macOS")
            date -v "+${weeks}w" "$format"
            ;;
        *)
            date -d "+${weeks} weeks" "$format" 2>/dev/null || date "$format"
            ;;
    esac
}

add_days_to_date() {
    local days="$1"
    local format="${2:-+%Y-%m-%d}"

    case "$PLATFORM" in
        "macOS")
            date -v "+${days}d" "$format"
            ;;
        *)
            date -d "+${days} days" "$format" 2>/dev/null || date "$format"
            ;;
    esac
}

# Configuration
# Handle BASH_SOURCE[0] being unbound when script is piped (curl | bash)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback: assume script is in current directory
    SCRIPT_DIR="$(pwd)"
fi
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$CLAUDE_DIR/templates"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/../.." && pwd)"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEMPLATE-GEN] $*"
}

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
    log "ERROR: jq is required but not installed"
    exit 1
fi

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

# Parse settings with fallbacks
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
SPRINT_END_DATE=$(add_weeks_to_date "$SPRINT_DURATION")
TODAY_PLUS_1=$(add_days_to_date 1)
SECURITY_STATUS=$([ "$SECURITY_ENABLED" = "true" ] && echo "Enabled" || echo "Disabled")

log "Generating documentation for $PROJECT_NAME ($PROJECT_TYPE) on $PLATFORM"

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

    # Process conditional blocks (simplified for cross-platform compatibility)
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

# Generate documentation files
for template in backlog dod sprint; do
    template_file="$TEMPLATES_DIR/${template}.template"
    output_file="$PROJECT_ROOT/${template^^}.md"

    if [[ -f "$template_file" ]]; then
        process_template "$template_file" "$output_file"
    else
        log "WARNING: Template $template_file not found, skipping"
    fi
done

# Update current sprint data
SPRINT_DATA_FILE="$CLAUDE_DIR/data/current_sprint.json"
if [[ -f "$SPRINT_DATA_FILE" ]]; then
    log "Updating sprint data file"

    # Create temporary file for JSON update
    TEMP_FILE=$(mktemp)
    jq ".activities += [{
        \"timestamp\": \"$GENERATION_DATE\",
        \"type\": \"documentation_update\",
        \"description\": \"Project documentation regenerated from templates\",
        \"platform\": \"$PLATFORM\"
    }] | .last_updated = \"$GENERATION_DATE\"" "$SPRINT_DATA_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SPRINT_DATA_FILE"
fi

log "Template generation completed successfully"
log "Generated files: BACKLOG.md, DOD.md, SPRINT.md"
log "All files are customized for $PROJECT_TYPE project: $PROJECT_NAME on $PLATFORM"
EOF

    chmod +x "$TARGET_DIR/.claude/scripts/template-generator.sh"
    print_success "Universal template generator created"
}

# Generate documentation using cross-platform template system
generate_docs() {
    print_step "Generating project documentation..."

    # Create the universal template generator first
    create_universal_template_generator

    # Run template generator
    local template_script="$TARGET_DIR/.claude/scripts/template-generator.sh"
    if [[ -f "$template_script" ]]; then
        "$template_script"
        print_success "Documentation generated using universal template system"
    else
        print_warning "Template generator not found, skipping documentation generation"
    fi
}

# Set up project-specific scripts with platform compatibility
setup_scripts() {
    print_step "Setting up project-specific scripts..."

    # Make scripts executable (with platform-specific handling)
    case "$PLATFORM" in
        "Windows"|"WSL")
            # Windows may not handle chmod correctly in all environments
            find "$TARGET_DIR/.claude/scripts/" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            find "$TARGET_DIR/.claude/hooks/" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            ;;
        *)
            chmod +x "$TARGET_DIR/.claude/scripts/"*.sh
            chmod +x "$TARGET_DIR/.claude/hooks/"*.sh
            ;;
    esac

    print_success "Scripts configured for $PROJECT_TYPE project on $PLATFORM"
}

# Initialize data directories with platform-specific handling
init_data() {
    print_step "Initializing data directories..."

    # Create required directories
    mkdir -p "$TARGET_DIR/.claude/data"
    mkdir -p "$TARGET_DIR/.claude/logs"
    mkdir -p "$TARGET_DIR/.claude/pids"

    # Create initial sprint data with cross-platform date handling
    local sprint_end_date
    sprint_end_date=$(add_weeks_to_date "$sprint_duration" "+%Y-%m-%dT%H:%M:%SZ")

    cat > "$TARGET_DIR/.claude/data/current_sprint.json" << EOF
{
  "sprint_number": 1,
  "start_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "end_date": "$sprint_end_date",
  "goal": "Set up $PROJECT_NAME with CC-Scrum framework and core development workflow",
  "status": "active",
  "story_points": {
    "planned": 8,
    "completed": 2,
    "remaining": 6
  },
  "activities": [
    {
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "type": "framework_installation",
      "description": "CC-Scrum framework installed and configured",
      "platform": "$PLATFORM",
      "installer_version": "$INSTALLER_VERSION"
    }
  ],
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    # Create initial context files
    echo "[]" > "$TARGET_DIR/.claude/data/tool_context.json"
    echo "[]" > "$TARGET_DIR/.claude/data/user_engagement.json"

    print_success "Data directories initialized"
}

# Post-installation summary with platform-specific info
show_summary() {
    print_step "Installation completed!"

    echo ""
    echo -e "${GREEN}🎉 CC-Scrum Framework Successfully Installed! 🎉${NC}"
    echo ""
    echo "Installation Details:"
    echo "  📁 Project: $PROJECT_NAME ($PROJECT_TYPE)"
    echo "  🖥️ Platform: $PLATFORM"
    echo "  📊 Coverage: ${coverage_threshold}%"
    echo "  🔒 Security: $([ "$security_scan" = "y" ] && echo "Enabled" || echo "Disabled")"
    echo "  👥 Agents: $(printf '%s ' "${ENABLED_AGENTS[@]}")"
    echo ""
    echo "Quick Start Commands:"
    echo "  🤖 Talk to agents: @po, @sm, @arch, @dev, @qa, @sec"
    echo "  📝 Review code: /review <file>"
    echo "  📋 Sprint status: /standup"
    echo "  🧠 Task breakdown: /meta-todo \"your complex task\""
    echo ""
    echo "Files Generated:"
    echo "  📄 BACKLOG.md - Product backlog management"
    echo "  ✅ DOD.md - Definition of Done criteria"
    echo "  📊 SPRINT.md - Sprint tracking dashboard"
    echo "  ⚙️ .claude/ - Complete framework installation"
    echo ""
    echo "Platform-Specific Notes:"
    case "$PLATFORM" in
        "macOS")
            echo "  🍎 macOS detected - using BSD date commands"
            if [[ "$BASH_MAJOR_VERSION" -lt 4 ]]; then
                echo "  ⚠️ Consider upgrading to bash 4+: brew install bash"
            fi
            ;;
        "Linux")
            echo "  🐧 Linux detected - using GNU date commands"
            ;;
        "WSL")
            echo "  🪟 Windows WSL detected - hybrid environment configured"
            ;;
        "Windows")
            echo "  🪟 Windows detected - Git Bash/MSYS2 environment"
            echo "  💡 Some features may require Linux-style tools"
            ;;
    esac
    echo ""
    echo "Next Steps:"
    echo "  1. Review generated documentation"
    echo "  2. Test quality gates: .claude/scripts/quality-gate-check.sh"
    echo "  3. Start using agents: @po \"create user story for main feature\""
    echo ""
    print_success "Happy coding with CC-Scrum on $PLATFORM! 🚀"
}

# Error handling with cleanup
cleanup_on_error() {
    print_error "Installation failed! Cleaning up..."
    if [[ -d "$TARGET_DIR/.claude" ]] && [[ "$TARGET_DIR/.claude" != "$FRAMEWORK_DIR" ]]; then
        rm -rf "$TARGET_DIR/.claude"
    fi
    exit 1
}

trap cleanup_on_error ERR

# Main installation flow
main() {
    show_banner
    log "Starting CC-Scrum framework installation on $PLATFORM"

    detect_platform
    check_prerequisites
    detect_project
    interactive_config
    copy_framework
    generate_config
    setup_scripts
    init_data
    generate_docs
    show_summary

    log "CC-Scrum framework installation completed successfully on $PLATFORM"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "CC-Scrum Framework Universal Installer v$INSTALLER_VERSION"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --help, -h         Show this help message"
            echo "  --unattended       Run in unattended mode with defaults"
            echo "  --dry-run          Show what would be installed without making changes"
            echo "  --verbose, -v      Enable verbose output"
            echo "  --nodejs           Force Node.js project type"
            echo "  --python           Force Python project type"
            echo "  --rust             Force Rust project type"
            echo "  --go               Force Go project type"
            echo ""
            echo "Supported Platforms:"
            echo "  🍎 macOS (with BSD date commands)"
            echo "  🐧 Linux (with GNU date commands)"
            echo "  🪟 Windows (Git Bash/WSL/MSYS2)"
            echo ""
            echo "The installer will:"
            echo "  1. Detect platform and project type automatically"
            echo "  2. Copy the CC-Scrum framework to .claude/ directory"
            echo "  3. Generate platform-specific configuration"
            echo "  4. Create project documentation with cross-platform templates"
            echo "  5. Set up background monitoring and quality gates"
            echo ""
            echo "Requirements:"
            echo "  - Bash 3.2+ (Bash 4+ recommended)"
            echo "  - jq (JSON processor)"
            echo "  - Write permissions in target directory"
            exit 0
            ;;
        --unattended)
            UNATTENDED_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN_MODE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE_MODE=true
            set -x
            shift
            ;;
        --nodejs)
            PROJECT_TYPE="nodejs"
            shift
            ;;
        --python)
            PROJECT_TYPE="python"
            shift
            ;;
        --rust)
            PROJECT_TYPE="rust"
            shift
            ;;
        --go)
            PROJECT_TYPE="go"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            print_info "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Handle dry run mode
if [[ "$DRY_RUN_MODE" == "true" ]]; then
    show_banner
    print_info "DRY RUN MODE - No changes will be made"
    detect_platform
    check_prerequisites
    detect_project
    print_info "Would install CC-Scrum framework for $PROJECT_TYPE project: $PROJECT_NAME on $PLATFORM"
    print_info "Would generate: BACKLOG.md, DOD.md, SPRINT.md, .claude/ directory"
    exit 0
fi

# Run main installation
main